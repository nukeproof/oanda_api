require 'spec_helper'
require 'uri'
require 'webmock/rspec'

describe "OandaAPI::Client" do
  describe ".query_string_normalizer" do
    let(:query_string_normalizer) { OandaAPI::Client.default_options[:query_string_normalizer] }

    it "responds to :call" do
      expect(query_string_normalizer.respond_to? :call).to be true
    end

    it "converts a hash to a query params string with camelized keys" do
      hash = { ruby_key1: 1 }
      expect(query_string_normalizer.call(hash)).to eq("rubyKey1=1")
    end

    it "sorts query parameters alphabetically" do
      hash = { ruby_key: 1, a_b_c: 1 }
      expect(query_string_normalizer.call(hash)).to eq("aBC=1&rubyKey=1")
    end

    it "URI encodes the parameter values" do
      hash = { key: "a,b,c" }
      expect(query_string_normalizer.call(hash)).to eq("key=a%2Cb%2Cc")
    end

    it "converts array values into comma-delimited strings" do
      hash = { key: %w(a b c) }
      expect(query_string_normalizer.call(hash)).to eq("key=a%2Cb%2Cc")
    end

    it "works with nil values" do
      hash = { camel_key: nil }
      expect(query_string_normalizer.call(hash)).to eq("camelKey")
    end
  end

  describe ".throttle_request_rate" do
    before(:all) do
      @throttle_setting = OandaAPI.configuration.use_request_throttling
    end
    after(:all) do
      OandaAPI.configuration.use_request_throttling = @throttle_setting
    end

    context "without request throttling" do
      it "does not throttle" do
        OandaAPI.configuration.use_request_throttling = false
        last_throttled_at = OandaAPI::Client.last_throttled_at

        (OandaAPI.configuration.max_requests_per_second + 2).times do
          OandaAPI::Client.throttle_request_rate
        end
        expect(OandaAPI::Client.last_throttled_at).to eq last_throttled_at
      end
    end

    context "with request throttling" do
      it "limits the number of requests per second" do
        OandaAPI.configuration.use_request_throttling = true
        before_throttled_at = Time.now

        (OandaAPI.configuration.max_requests_per_second + 2).times do
          OandaAPI::Client.throttle_request_rate
        end
        expect(OandaAPI::Client.last_throttled_at).to be > before_throttled_at
      end
    end
  end

  describe "#api_uri" do
    let(:client) { Struct.new(:domain) { include OandaAPI::Client }.new }
    it "is domain specific" do
      uris = {}
      OandaAPI::DOMAINS.each do |domain|
        client.domain = domain
        uris[client.api_uri("/path")] = domain
      end
      expect(uris.size).to eq(3)
    end

    it "is an absolute URI" do
      OandaAPI::DOMAINS.each do |domain|
        client.domain = domain
        uri = URI.parse client.api_uri("/path")
        expect(uri.absolute?).to be true
      end
    end
  end

  describe "#execute_request" do
    let(:client) { OandaAPI::Client::UsernameClient.new "spongebob" }

    it "returns a response for a successful request" do
      stub_request(:get, "http://api-sandbox.oanda.com/v1/accounts?username=spongebob")
        .to_return(status: 200, body: "{\"accounts\" : []}", headers: { "content-type" => "application/json" })
      expect(client.execute_request(:get, "/accounts")).to be_an OandaAPI::ResourceCollection
    end

    it "raises OandaAPI::RequestError for an invalid request" do
      stub_request(:get, "http://api-sandbox.oanda.com/v1/accounts/a_bad_request?username=spongebob")
        .to_return(status:  [404, "Something bad happened (but we still love you)."])
      expect { client.execute_request :get, "/accounts/a_bad_request" }.to raise_error(OandaAPI::RequestError)
    end
  end
end
