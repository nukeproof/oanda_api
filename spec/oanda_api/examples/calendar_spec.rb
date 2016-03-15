require 'spec_helper'
require 'support/client_helper'

describe "OandaAPI::Resource::Calendar" do
  let(:client) { ClientHelper.client }

  describe "Calendar" do
    it "gets economic calendar informations", :vcr do
      VCR.use_cassette("calendar(options).get") do
        events = client.calendar(instrument: 'EUR_CAD',
                                     period: '2592000')
                            .get
        expect(events.first).to be_an OandaAPI::Resource::Calendar
      end
    end
  end

end
