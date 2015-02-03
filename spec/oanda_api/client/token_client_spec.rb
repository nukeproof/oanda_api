require 'spec_helper'

describe "OandaAPI::Client::TokenClient" do
  let(:client) { OandaAPI::Client::TokenClient.new(:practice, "token") }

  describe "#initialize" do
    it "creates a TokenClient instance" do
      expect(client).to be_a(OandaAPI::Client::TokenClient)
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
