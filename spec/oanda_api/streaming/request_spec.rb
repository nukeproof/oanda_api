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
        {"transaction":{"id": 1}}\r
        {"transaction":{"id": 2}}\r
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
          {"heartbeat":{"id" : 0}}\r
          {"transaction":{"id": 1}}\r
          {"heartbeat":{"id" : 0}}\r
          {"transaction":{"id": 2}}\r
          {"heartbeat":{"id" : 0}}\r
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
          {"heartbeat":{"id" : 10}}\r
          {"transaction":{"id": 1}}\r
          {"heartbeat":{"id" : 20}}\r
          {"transaction":{"id": 2}}\r
          {"heartbeat":{"id" : 30}}\r
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
          {"transaction":{"id": 1}}\r
          {"disconnect":{"code":60,"message":"Access Token connection limit exceeded"}}\r
          {"transaction":{"id": 2}}\r
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
          {"transaction":{"id": 1}}\r
          {"sponge-bob":{"is": "awesome"}}\r
          {"transaction":{"id": 2}}\r
        END

        stub_request(:any, /\.com/).to_return(body: events_json, status: 200)
        expect {
          streaming_request.stream { |resource| resource }
        }.to raise_error(OandaAPI::RequestError, /unknown resource/)
      end
    end

    it "yields an object that responds to stop! and terminates streaming when called" do
      events_json = <<-END
      {"transaction":{"id": 1}}\r
      {"transaction":{"id": 2}}\r
      {"transaction":{"id": 3}}\r
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
        {"heartbeat":{"id": 1}}\r
        {"heartbeat":{"id": 2}}\r
        {"heartbeat":{"id": 3}}\r
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
        {"tick":{"bid": 1}}{"tick":{"bid": 2}}\r{"tick":{"bid": 3}}\r
      END

      it "yields all of the objects" do
        case
        when gem_installed?(:Yajl)
          OandaAPI::Streaming::JsonParser.use(:yajl)
        when gem_installed?(:Gson)
          OandaAPI::Streaming::JsonParser.use(:gson)
        else
          OandaAPI::Streaming::JsonParser.use(:generic)
        end

        stub_request(:any, /\.com/).to_return(body: events_json, status: 200)
        ticks = []
        streaming_request.stream do |resource|
          ticks << resource.bid
        end
        expect(ticks).to contain_exactly(1, 2, 3)
      end
    end

    context "when the stream contains incomplete chunks" do
      it "yields all of the objects grouping them" do
        case
        when gem_installed?(:Yajl)
          OandaAPI::Streaming::JsonParser.use(:yajl)
        when gem_installed?(:Gson)
          OandaAPI::Streaming::JsonParser.use(:gson)
        else
          OandaAPI::Streaming::JsonParser.use(:generic)
        end

        WebMock.disable!

        client = Net::HTTP.new('a.url.com', 443)
        allow(Net::HTTP).to receive(:new).with('a.url.com', 443).and_return(client)
        http_response_json = <<-END
HTTP/1.1 200 OK
Content-Type: application/json
Transfer-Encoding: chunked

25
{"tick":{"bid": 1}}{"tick":{"bid": 2}

16
}{"tick":{"bid": 3}}\r\n

0

END

        socket = Net::BufferedIO.new(StringIO.new(http_response_json))
        response = Net::HTTPResponse.read_new(socket)
        allow(client).to receive(:request).and_yield(response)

        response.reading_body(socket, true) do
          ticks = []
          streaming_request.stream do |resource|
            ticks << resource.bid
          end
          expect(ticks.last).to eq(3)
        end

        WebMock.enable!
      end
    end
  end
end
