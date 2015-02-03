require 'spec_helper'

describe "OandaAPI::Client::UsernameClient" do
  let(:client) { OandaAPI::Client::UsernameClient.new("spongebob") }

  describe "#initialize" do
    it "sets the username" do
      expect(client.username).to eq("spongebob")
    end

    it "sets domain to sandbox" do
      expect(client.domain).to eq(:sandbox)
    end

    it "sets default_params to include username" do
      expect(client.default_params).to include("username" => "spongebob")
    end
  end

  describe "#auth" do
    it "returns a hash with username" do
      expect(client.auth["username"]).to eq("spongebob")
    end
  end

  describe "#default_params" do
    it "initialize as #auth" do
      expect(client.default_params).to eq(client.auth)
    end
  end
end
