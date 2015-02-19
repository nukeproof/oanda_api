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

    it "sets default_params to {}" do
      expect(client.default_params).to eq({})
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

  describe "default_params" do
    it "has a reader and writer" do
      client.default_params = { key: "value" }
      expect(client.default_params).to eq(key: "value")
    end
  end

  describe "headers" do
    it "has a reader and writer" do
      client.headers = { key: "value" }
      expect(client.headers).to eq(key: "value")
    end
  end
end