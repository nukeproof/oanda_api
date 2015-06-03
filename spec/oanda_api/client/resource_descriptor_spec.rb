require 'spec_helper'

describe "OandaAPI::Client::ResourceDescriptor" do
  describe "#initialize" do
    let(:resource_descriptor) { OandaAPI::Client::ResourceDescriptor.new "/accounts", :get }
    it "sets path" do
      expect(resource_descriptor.path).to eq("/accounts")
    end

    context 'when path resource is equal alltransactions' do
      let(:resource_descriptor) { OandaAPI::Client::ResourceDescriptor.new "/account/123/alltransactions", :get }

      it 'is sets TransactionHistory as resource_klass' do
        expect(resource_descriptor.resource_klass).to eq(OandaAPI::Resource::TransactionHistory)
      end

      it 'is sets @is_collection to false' do
        expect(resource_descriptor.is_collection?).to be false
      end
    end
  end

  context "when the path ends with a known resource" do
    let(:resource_descriptor) { OandaAPI::Client::ResourceDescriptor.new "/account/123/orders", :get }

    describe "#resource_klass" do
      it "is the requested resource class" do
        expect(resource_descriptor.resource_klass).to be(OandaAPI::Resource::Order)
      end
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
end
