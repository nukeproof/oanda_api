require 'spec_helper'
require 'support/client_helper'

describe "OandaAPI::Resource::Trade" do
  let(:account) { ClientHelper.account }

  it "gets a list of trades", :vcr do
    VCR.use_cassette("trades.get") do
      ClientHelper.create_trade
      trades = account.trades.get
      expect(trades.first).to be_an OandaAPI::Resource::Trade
    end
  end

  it "gets a filtered list of trades", :vcr do
    VCR.use_cassette("trades(filter).get") do
      ClientHelper.create_trade(instrument: "USD_JPY")
      trades = account.trades(instrument: "USD_JPY").get
      expect(trades.first).to be_an OandaAPI::Resource::Trade
    end
  end

  it "gets information on a specific trade", :vcr do
    VCR.use_cassette("trade(id).get") do
      trade_id = ClientHelper.create_trade.trade_opened.id
      trade = account.trade(trade_id).get
      expect(trade).to be_an OandaAPI::Resource::Trade
    end
  end

  it "modifies an open trade " do
    VCR.use_cassette("trade(options).modify") do
      order = ClientHelper.create_trade
      modified_order =
        account.trade(id: order.trade_opened.id, take_profit: order.price + 2.0)
               .update
      expect(modified_order).to be_an OandaAPI::Resource::Trade
    end
  end

  it "closes an open trade" do
    VCR.use_cassette("trade(id).close") do
      ClientHelper.create_trade(instrument: "USD_JPY").trade_opened.id

      # Get the oldest open trade for USD_JPY, so we can close that trade.
      oldest_trade =
        account.trades(instrument: "USD_JPY")
               .get
               .min_by(&:id)

      closed_trade = account.trade(oldest_trade.id).close
      expect(closed_trade).to be_an OandaAPI::Resource::Trade

      open_trades = account.trades.get
      expect(open_trades.map(&:id)).to_not include oldest_trade.id
    end
  end
end
