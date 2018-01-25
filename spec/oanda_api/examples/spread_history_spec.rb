require 'spec_helper'
require 'support/client_helper'

describe "OandaAPI::Resource::Labs::SpreadHistory" do
  let(:client) { ClientHelper.client }

  it "gets spread history for an instrument and a period", :vcr do
    VCR.use_cassette("spreads.get") do
      spread_history = client.spreads(instrument: "EUR_CAD", period: 3600).get
      expect(spread_history).to be_an OandaAPI::Resource::Labs::SpreadHistory

      expect(spread_history.averages.first.spread).to be_a Numeric
      expect(spread_history.averages.first.timestamp).to be_a Integer
      expect(spread_history.averages.first.time).to be_a Time

      expect(spread_history.maximums.first.spread).to be_a Numeric
      expect(spread_history.maximums.first.timestamp).to be_a Integer
      expect(spread_history.maximums.first.time).to be_a Time

      expect(spread_history.minimums.first.spread).to be_a Numeric
      expect(spread_history.minimums.first.timestamp).to be_a Integer
      expect(spread_history.minimums.first.time).to be_a Time
    end
  end

  it "can use the alias: spread_history", :vcr do
    VCR.use_cassette("spread_history.get") do
      spread_history = client.spread_history(instrument: "EUR_CAD", period: 3600).get
      expect(spread_history).to be_an OandaAPI::Resource::Labs::SpreadHistory
    end
  end
end
