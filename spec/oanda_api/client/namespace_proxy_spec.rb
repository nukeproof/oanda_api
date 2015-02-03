require 'spec_helper'

describe "OandaAPI::Client::NamespaceProxy" do
  let(:client) { OandaAPI::Client::UsernameClient.new("spongebob") }
  let(:namespace_proxy) { OandaAPI::Client::NamespaceProxy.new client, "account" }

  describe "#initialize" do
    it "raises ArgumentError unless an OandaAPI::Client is passed" do
      expect { OandaAPI::Client::NamespaceProxy.new nil, "account" }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError unless a non-empty namespace string is passed" do
      expect { OandaAPI::Client::NamespaceProxy.new client, "" }.to raise_error(ArgumentError)
    end
  end
end
