require 'spec_helper'

describe "OandaAPI::Client::ResourceDescriptor" do
  describe "#initialize" do
    let(:resource_descriptor) { OandaAPI::Client::ResourceDescriptor.new "/accounts", :get }

    it "sets the path " do
      expect(resource_descriptor.path).to eq("/accounts")
    end

    context "non-standard (special case) resources" do
      describe "special case: '/alltransactions'" do
        let(:resource_descriptor) { OandaAPI::Client::ResourceDescriptor.new "/account/123/alltransactions", :get }

        it "sets TransactionHistory as its resource_klass" do
          expect(resource_descriptor.resource_klass).to eq(OandaAPI::Resource::TransactionHistory)
        end

        it "sets @is_collection to false" do
          expect(resource_descriptor.is_collection?).to be false
        end
      end

      describe "special case: '/calendar'" do
        let(:resource_descriptor) { OandaAPI::Client::ResourceDescriptor.new "/calendar", :get }

        it "sets CalendarEvents as its resource_klass" do
          expect(resource_descriptor.resource_klass).to eq(OandaAPI::Resource::Labs::CalendarEvent)
        end

        it "sets @is_collection to true, despite its path name being singular" do
          expect(resource_descriptor.is_collection?).to be true
        end
      end

      describe "special case: '/calendar_events'" do
        let(:resource_descriptor) { OandaAPI::Client::ResourceDescriptor.new "/calendar_events", :get }

        it "uses /calendar as the true API resource name" do
          expect(resource_descriptor.path).to eq "/calendar"
        end
      end
    end
  end

  context "when the path ends with an unknown resource" do
    it "doesn't allow invalid resources" do
      expect { OandaAPI::Client::ResourceDescriptor.new "/invalid_resource" }.to raise_error(ArgumentError)
    end
  end

  describe "#is_collection?" do
    it "is true for GET requests without a resource id" do
      resource_descriptor = OandaAPI::Client::ResourceDescriptor.new "/account/123/orders", :get
      expect(resource_descriptor.is_collection?).to be true
    end

    it "is false for GET requests with a resource id" do
      resource_descriptor = OandaAPI::Client::ResourceDescriptor.new "/account/123", :get
      expect(resource_descriptor.is_collection?).to be false
    end

    it "is false for non-GET requests" do
      [:delete, :patch, :post].each do |verb|
        resource_descriptor = OandaAPI::Client::ResourceDescriptor.new "/account", verb
        expect(resource_descriptor.is_collection?).to be false
      end
    end
  end

  describe "#labs?" do
    it "is true for 'Labs' resources" do
      resource_descriptor = OandaAPI::Client::ResourceDescriptor.new "/calendar", :get
      expect(resource_descriptor.labs?).to be true
    end

    it "is false for non 'Labs' resources" do
      resource_descriptor = OandaAPI::Client::ResourceDescriptor.new "/account", :get
      expect(resource_descriptor.labs?).to be false
    end
  end
end
