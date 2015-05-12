require 'spec_helper'
require 'uri'
require 'webmock/rspec'

describe "OandaAPI::Streaming::Request" do

  let(:streaming_request) {
    OandaAPI::Streaming::Request.new(uri: "https://a.url.com",
                                     query: { account: 1234, instruments: %w[AUD_CAD AUD_CHF] },
                                     headers: { "some-header" => "header value" })
  }

  describe "#initialize" do
    it "creates a Streaming::Request instance" do
      expect(streaming_request).to be_an(OandaAPI::Streaming::Request)
    end

    it "initializes the uri attribute" do
      expect(streaming_request.uri.to_s).to eq "https://a.url.com?account=1234&instruments=AUD_CAD%2CAUD_CHF"
    end

    it "initializes the request headers attribute" do
      expect(streaming_request.request["some-header"]).to eq "header value"
    end

    it "initializes the request's client attribute" do
      client = OandaAPI::Streaming::Client.new :practice, "token"
      streaming_request = OandaAPI::Streaming::Request.new(client: client,
                                                           uri: "https://a.url.com",
                                                           query: { account: 1234, instruments: %w[AUD_CAD AUD_CHF] },
                                                           headers: { "some-header" => "header value" })
      expect(streaming_request.client).to eq client
    end
  end

  describe "#client=" do
    it "sets the request's client attribute" do
      client = OandaAPI::Streaming::Client.new(:practice, "token")
      streaming_request.client = client
      expect(streaming_request.client).to eq client
    end

    it "fails if the value is not an Oanda::Streaming::Client" do
      expect { streaming_request.client = "" }.to raise_error(ArgumentError)
    end
  end

  describe "#stop!" do
    it "sets the stop_requested signal" do
      expect(streaming_request.stop_requested?).to be false
      streaming_request.stop!
      expect(streaming_request.stop_requested?).to be true
    end
  end

  describe "#stream" do
    it "yields all resources returned in the response stream" do
      events_json = <<-END
        {"transaction":{"id": 1}}\r\n
        {"transaction":{"id": 2}}
      END
      ids = []
      stub_request(:any, /\.com/).to_return(body: events_json, status: 200)

      streaming_request.stream do |resource|
        ids << resource.id
      end
      expect(ids).to contain_exactly(1, 2)
    end

    context "when emit_heartbeats? is false" do
      it "ignores 'heartbeats' in the response stream" do
        events_json = <<-END
          {"heartbeat":{"id" : 0}}\r\n
          {"transaction":{"id": 1}}\r\n
          {"heartbeat":{"id" : 0}}\r\n
          {"transaction":{"id": 2}}\r\n
          {"heartbeat":{"id" : 0}}
        END
        ids =  []
        stub_request(:any, /\.com/).to_return(body: events_json, status: 200)
        streaming_request.emit_heartbeats = false
        streaming_request.stream { |resource| ids << resource.id }
        expect(ids).to contain_exactly(1, 2)
      end
    end

    context "when emit_heartbeats? is true" do
      it "includes 'heartbeats' in the response stream" do
        events_json = <<-END
          {"heartbeat":{"id" : 10}}\r\n
          {"transaction":{"id": 1}}\r\n
          {"heartbeat":{"id" : 20}}\r\n
          {"transaction":{"id": 2}}\r\n
          {"heartbeat":{"id" : 30}}
        END
        transactions = []
        heartbeats = 0
        stub_request(:any, /\.com/).to_return(body: events_json, status: 200)
        streaming_request.emit_heartbeats = true
        streaming_request.stream do |resource|
          if resource.is_a? OandaAPI::Resource::Heartbeat
            heartbeats += 1
          else
            transactions << resource.id
          end
        end
        expect(transactions).to contain_exactly(1, 2)
        expect(heartbeats).to be 3
      end
    end

    context "when a 'disconnect' is received the response stream" do
      it "raises an OandaAPI::StreamingDisconnect" do
        events_json = <<-END
          {"transaction":{"id": 1}}\r\n
          {"disconnect":{"code":60,"message":"Access Token connection limit exceeded"}}\r\n
          {"transaction":{"id": 2}}
        END

        stub_request(:any, /\.com/).to_return(body: events_json, status: 200)
        expect {
          streaming_request.stream { |resource| resource }
        }.to raise_error(OandaAPI::StreamingDisconnect, /connection limit exceeded/)
      end
    end

    context "when an unknown resource type is received the response stream" do
      it "raises an OandaAPI::RequestError" do
        events_json = <<-END
          {"transaction":{"id": 1}}\r\n
          {"sponge-bob":{"is": "awesome"}}\r\n
          {"transaction":{"id": 2}}
        END

        stub_request(:any, /\.com/).to_return(body: events_json, status: 200)
        expect {
          streaming_request.stream { |resource| resource }
        }.to raise_error(OandaAPI::RequestError, /unknown resource/)
      end
    end

    it "yields an object that responds to stop! and terminates streaming when called" do
      events_json = <<-END
      {"transaction":{"id": 1}}\r\n
      {"transaction":{"id": 2}}\r\n
      {"transaction":{"id": 3}}
      END
      stub_request(:any, /\.com/).to_return(body: events_json, status: 200)
      ids = []
      streaming_request.stream do |resource, signaller|
        ids << resource.id
        signaller.stop! if ids.size > 1
      end
      expect(ids).to contain_exactly(1, 2)
    end

    context "when the stream contains only heartbeats" do
      it "terminates streaming when a stop signal is received" do
        events_json = <<-END
        {"heartbeat":{"id": 1}}\r\n
        {"heartbeat":{"id": 2}}\r\n
        {"heartbeat":{"id": 3}}
        END
        stub_request(:any, /\.com/).to_return(body: events_json, status: 200)
        heartbeats = 0
        streaming_request.emit_heartbeats = true
        streaming_request.stream do |_resource, signaller|
          heartbeats += 1
          signaller.stop!
        end
        expect(heartbeats).to eq 1
      end
    end

    context "when the stream contains multiple undelimited objects" do
      events_json = <<-END
        {"tick":{"bid": 1}}{"tick":{"bid": 2}}\r\n{"tick":{"bid": 3}}
      END

      context "when using the generic JSON parser" do
        it "raises a parsing error" do
          OandaAPI::Streaming::JsonParser.use :generic
          stub_request(:any, /\.com/).to_return(body: events_json, status: 200)

          expect {
            streaming_request.stream { |resource, signaller| signaller.stop! }
          }.to raise_error(JSON::ParserError)
        end
      end

      context "when using a streaming JSON parser" do
        it "yields all of the objects" do
          jruby? ? OandaAPI::Streaming::JsonParser.use(:gson) : OandaAPI::Streaming::JsonParser.use(:yajl)
          stub_request(:any, /\.com/).to_return(body: events_json, status: 200)
          bids = []
          streaming_request.stream do |resource|
            bids << resource.bid
          end
          expect(bids.size).to eq 3
        end
      end
    end
  end
end
