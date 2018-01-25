require 'spec_helper'
require 'uri'
require 'webmock/rspec'

describe "OandaAPI::Streaming::Client" do
  let(:client) { OandaAPI::Streaming::Client.new(:practice, "token") }

  describe "#initialize" do
    it "creates a Streaming::Client instance" do
      expect(client).to be_a(OandaAPI::Streaming::Client)
    end

    it "sets the authorization token" do
      expect(client.auth_token).to eq("token")
    end

    it "sets the domain" do
      expect(client.domain).to eq(:practice)
    end

    it "sets authorization headers" do
      expect(client.headers).to eq(client.auth)
    end

    it "defaults emit_heartbeats to false" do
      expect(client.emit_heartbeats?).to be false
    end
  end

  describe "#api_uri" do
    let(:client) { Struct.new(:domain) { include OandaAPI::Client }.new }
    let(:resource_descriptor) {OandaAPI::Client::ResourceDescriptor.new "/accounts", :get}
    it "is domain specific" do
      uris = {}
      OandaAPI::DOMAINS.each do |domain|
        client.domain = domain
        uris[client.api_uri(resource_descriptor)] = domain
      end
      expect(uris.size).to eq(3)
    end

    it "is an absolute URI" do
      OandaAPI::DOMAINS.each do |domain|
        client.domain = domain
        uri = URI.parse client.api_uri(resource_descriptor)
        expect(uri.absolute?).to be true
      end
    end
  end

  describe "#auth" do
    it "returns a hash with an Authorization key" do
      expect(client.auth["Authorization"]).to eq("Bearer token")
    end
  end

  describe "#domain=" do
    OandaAPI::DOMAINS.each do |domain|
      it "allows domain :#{domain} " do
        client.domain = domain
        expect(client.domain).to be(domain)
      end
    end

    it "doesn't allow invalid domains" do
      expect { client.domain = :bogus }.to raise_error(ArgumentError)
    end
  end

  describe "#emit_heartbeats=" do
    it "sets the emits heartbeats attribute" do
      [true, false].each do |value|
        client.emit_heartbeats = value
        expect(client.emit_heartbeats?).to be value
      end
    end

    it "includes heartbeats when true" do
      events_json = <<-END
      {"heartbeat":{"time":"2014-05-26T13:58:40Z"}}\r
      {"transaction":{"id":10001}}\r
      {"transaction":{"id":10002}}\r
      END

      client = OandaAPI::Streaming::Client.new(:practice, "token")
      stub_request(:get, "https://stream-fxpractice.oanda.com/v1/events").to_return(body: events_json, status: 200)

      [{emit_heartbeats: true,  heartbeats: 1, non_heartbeats: 2},
       {emit_heartbeats: false, heartbeats: 0, non_heartbeats: 2}].each do |test|

        client.emit_heartbeats = test[:emit_heartbeats]
        heartbeats = non_heartbeats = 0
        client.events.stream do |resource|
          if resource.is_a? OandaAPI::Resource::Heartbeat
            heartbeats += 1
          else
            non_heartbeats += 1
          end
        end
        expect(heartbeats).to eq test[:heartbeats]
        expect(non_heartbeats).to eq test[:non_heartbeats]
      end
    end
  end

  describe "headers" do
    it "has a reader and writer" do
      client.headers = { key: "value" }
      expect(client.headers).to eq(key: "value")
    end
  end

  describe "#running?" do
    it "returns true if a streaming request is running" do
      events_json = <<-END
      {"heartbeat":{"time":"2014-05-26T13:58:40Z"}}\r
      {"transaction":{"id":10001}}\r
      {"transaction":{"id":10002}}\r
      END
      stub_request(:get, "https://stream-fxpractice.oanda.com/v1/events").to_return(body: events_json, status: 200)

      client = OandaAPI::Streaming::Client.new(:practice, "token")
      expect(client.running?).to be false
      client.events.stream do |_event, signaller|
        expect(client.running?).to be true
        signaller.stop!
      end
    end
  end

  describe "#stop!" do
    events_json = <<-END
      {"transaction":{"id": 1}}\r
      {"transaction":{"id": 2}}\r
    END

    context "without using #stop!" do
      it "emits all objects in the stream" do
        stub_request(:get, "https://stream-fxpractice.oanda.com/v1/events").to_return(body: events_json, status: 200)
        client = OandaAPI::Streaming::Client.new(:practice, "token")
        event_ids = []
        client.events.stream { |event| event_ids << event.id }
        expect(event_ids).to contain_exactly(1, 2)
      end
    end

    context "when using #stop!" do
      it "terminates emitting objects in the stream" do
        stub_request(:get, "https://stream-fxpractice.oanda.com/v1/events").to_return(body: events_json, status: 200)
        client = OandaAPI::Streaming::Client.new(:practice, "token")
        event_ids = []
        client.events.stream do |event, signaller|
          event_ids << event.id
          signaller.stop!
        end
        expect(event_ids).to contain_exactly(1)
      end
    end
  end
end
