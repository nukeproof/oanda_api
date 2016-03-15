require 'spec_helper'
require 'support/client_helper'

describe "OandaAPI::Resource::Position" do
  let(:account) { ClientHelper.account }

  it "gets all open positions", :vcr do
    VCR.use_cassette("positions.get") do
      ClientHelper.create_trade
      positions = account.positions.get
      expect(positions.first).to be_an OandaAPI::Resource::Position
    end
  end

  it "gets the position for an instrument", :vcr do
    VCR.use_cassette("positions(instrument).get") do
      ClientHelper.create_trade(instrument: "USD_JPY")
      position = account.positions("USD_JPY").get
      expect(position).to be_an OandaAPI::Resource::Position
    end
  end

  it "closes an existing position", :vcr do
    VCR.use_cassette("positions(instrument).close") do
      ClientHelper.create_trade(instrument: "USD_JPY")

      # Verify we have an open position.
      position = account.position("USD_JPY").get
      expect(position).to be_an OandaAPI::Resource::Position

      account.position("USD_JPY").close

      # Verify that the position has been closed.
      positions = account.positions.get
      expect(positions.map(&:instrument)).to_not include "USD_JPY"
    end
  end
end
