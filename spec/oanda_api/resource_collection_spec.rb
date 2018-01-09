require 'spec_helper'

describe "OandaAPI::ResourceCollection" do
  let(:resource_descriptor) { OandaAPI::Client::ResourceDescriptor.new "/candles", :get }

  describe "#initialize" do
    context "with a collection attribute matching the one expected by the resource descriptor" do
      let(:resource_collection) { OandaAPI::ResourceCollection.new({ candles: [{ volume: 10 }] }, resource_descriptor) }

      it "returns a ResourceCollection" do
        expect(resource_collection).to be_an(OandaAPI::ResourceCollection)
      end

      it "is Enumerable" do
        expect(resource_collection).to be_an Enumerable
      end

      it "contains elements of the expected resource" do
        expect(resource_collection.first).to be_an OandaAPI::Resource::Candle
      end

      it "contains initialized resource elements" do
        expect(resource_collection.first.volume).to eq 10
      end

      describe "when the collection element is empty" do
        let(:resource_collection) { OandaAPI::ResourceCollection.new({ candles: [] }, resource_descriptor) }
        it "returns a ResourceCollection" do
          expect(resource_collection).to be_an(OandaAPI::ResourceCollection)
        end
        it "is an empty collection" do
          expect(resource_collection.empty?).to be true
        end
      end

      describe "with extra attributes" do
        let(:resource_collection) { OandaAPI::ResourceCollection.new({ candles: [], extra: "I'm special" }, resource_descriptor) }

        it "returns a ResourceCollection" do
          expect(resource_collection).to be_an(OandaAPI::ResourceCollection)
        end

        it "has an accessor for the extra attributes" do
          expect(resource_collection.extra).to eq "I'm special"
        end
      end

      describe "with location argument" do
        let(:resource_collection) { OandaAPI::ResourceCollection.new({ candles: []}, resource_descriptor, location: "/some/resource/id" ) }

        it "has a location accessor" do
          expect(resource_collection.location).to eq "/some/resource/id"
        end
      end

    end

    context "without the collection attribute expected by the resource descriptor " do
      let(:resource_collection) { OandaAPI::ResourceCollection.new({}, resource_descriptor) }

      it "returns a ResourceCollection" do
        expect(resource_collection).to be_an(OandaAPI::ResourceCollection)
      end

      it "is Enumerable" do
        expect(resource_collection).to be_an Enumerable
      end

      it "is an empty collection" do
        expect(resource_collection.empty?).to be true
      end

      describe "with extra attributes" do
        let(:resource_collection) { OandaAPI::ResourceCollection.new({ extra: "I'm special" }, resource_descriptor) }

        it "returns a ResourceCollection" do
          expect(resource_collection).to be_an(OandaAPI::ResourceCollection)
        end

        it "has an accessor for the extra attribute" do
          expect(resource_collection.extra).to eq "I'm special"
        end
      end
    end

    context "with nil" do
      let(:resource_collection) { OandaAPI::ResourceCollection.new(nil, resource_descriptor) }

      it "returns a ResourceCollection" do
        expect(resource_collection).to be_an(OandaAPI::ResourceCollection)
      end

      it "is Enumerable" do
        expect(resource_collection).to be_an Enumerable
      end

      it "is an empty collection" do
        expect(resource_collection.empty?).to be true
      end
    end
  end

  describe "#respond_to?" do
    let(:resource_collection) { OandaAPI::ResourceCollection.new({ candles: [], extra: "I'm special" }, resource_descriptor) }

    it "responds to collection methods" do
      expect(resource_collection.respond_to?(:shuffle)).to be true
    end

    it "responds to dynamic accessors for extra attributes" do
      expect(resource_collection.respond_to?(:extra)).to be true
    end

    it "responds to concrete accessors" do
      expect(resource_collection.respond_to?(:location)).to be true
    end
  end
end
