require 'spec_helper'
require 'support/client_helper'

describe "OandaAPI::Transaction" do
  let(:account) { ClientHelper.account }

  it "gets transaction history" do
    VCR.use_cassette("account(id).transactions(options).get") do
      ClientHelper.create_trade(instrument: "USD_JPY")
      transactions = account.transactions(instrument: "USD_JPY").get
      expect(transactions.first).to be_an OandaAPI::Resource::Transaction
    end
  end

  it "gets information for a specific transaction" do
    VCR.use_cassette("account(id).transaction(id).get") do
      ClientHelper.create_trade(instrument: "USD_JPY")
      id = account.transactions(instrument: "USD_JPY").get.first.id
      transaction = account.transaction(id).get
      expect(transaction).to be_an OandaAPI::Resource::Transaction
      expect(transaction.trade_opened).to be_a OandaAPI::Resource::Transaction::TradeOpened
    end
  end
end
