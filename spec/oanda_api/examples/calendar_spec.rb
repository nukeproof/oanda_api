require 'spec_helper'
require 'support/client_helper'

describe "OandaAPI::Resource::Labs::CalendarEvent" do
  let(:client) { ClientHelper.client }

  it "gets economic calendar events related to an instrument", :vcr do
    VCR.use_cassette("calendar(instrument_and_period).get") do
      events = client.calendar(instrument: "EUR_CAD", period: 604800).get
      expect(events.first).to be_an OandaAPI::Resource::Labs::CalendarEvent
    end
  end

  it "gets all economic calendar events for a period", :vcr do
    VCR.use_cassette("calendar(period).get") do
      events = client.calendar(period: 86400).get
      expect(events.first).to be_an OandaAPI::Resource::Labs::CalendarEvent
    end
  end

  it "can use the alias: calendar_events", :vcr do
    VCR.use_cassette("calendar_events(period).get") do
      events = client.calendar_events(period: 86400).get
      expect(events.first).to be_an OandaAPI::Resource::Labs::CalendarEvent
    end
  end
end
