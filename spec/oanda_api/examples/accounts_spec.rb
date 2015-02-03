require 'spec_helper'
require 'support/client_helper'

describe "OandaAPI::Resource::Account" do
  let(:client) { ClientHelper.client }

  it "creates a new account" do
    VCR.use_cassette("accounts.create") do
      account = client.accounts.create
      expect(account).to be_an OandaAPI::Resource::Account
    end
  end

  it "gets all accounts", :vcr do
    VCR.use_cassette("accounts.get") do
      accounts = client.accounts.get
      expect(accounts.first).to be_an OandaAPI::Resource::Account
    end
  end

  it "gets a specific account", :vcr do
    VCR.use_cassette("accounts(id).get") do
      account_id = client.accounts.get.first.account_id
      account = client.accounts(account_id).get
      expect(account).to be_an OandaAPI::Resource::Account
    end
  end
end
