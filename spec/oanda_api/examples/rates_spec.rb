require 'spec_helper'
require 'support/client_helper'

describe "OandaAPI::Resource" do
  let(:client) { ClientHelper.client }

  describe "Instrument" do
    it "gets all instruments", :vcr do
      VCR.use_cassette("instruments.get") do
        instruments = client.instruments.get
        expect(instruments.first).to be_an OandaAPI::Resource::Instrument
      end
    end

    it "gets a filtered list of instruments", :vcr do
      VCR.use_cassette("instruments(options).get") do
        instruments = client.instruments(instruments: %w(EUR_USD EUR_CAD),
                                              fields: %w(pip precision))
                            .get
        expect(instruments.first).to be_an OandaAPI::Resource::Instrument
      end
    end
  end

  describe "Price" do
    it "gets a filtered list of prices", :vcr do
      VCR.use_cassette("prices(options).get") do
        prices = client.prices(instruments: %w(EUR_USD EUR_CAD)).get
        expect(prices.first).to be_an OandaAPI::Resource::Price
      end
    end
  end

  describe "Candle" do
    it "gets candles for an instrument", :vcr do
      VCR.use_cassette("candles(options).get") do
        candles = client.candles(instrument: "EUR_USD",
                                granularity: "M1",
                                      count: 1,
                              candle_format: "midpoint")
                        .get
        expect(candles.first).to be_an OandaAPI::Resource::Candle
      end
    end
  end
end
