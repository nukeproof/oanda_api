require 'spec_helper'
describe "OandaAPI::ResourceBase" do
  class SomeResource < OandaAPI::ResourceBase
    attr_accessor :webbed_feet
  end

  class SomeResourceCustomized < OandaAPI::ResourceBase
    attr_accessor :webbed_feet

    def custom_attributes
      super.merge(webbed_feet: "customized #{webbed_feet}")
    end
  end

  describe ".class_from_symbol" do
    it "returns the Class for a resource name" do
      expect(OandaAPI::ResourceBase.class_from_symbol(:account)).to be OandaAPI::Resource::Account
    end

    let(:baby_klass) { module OandaAPI; class Mama < OandaAPI::ResourceBase; end; end; module OandaAPI; class Baby < Mama; end; end; OandaAPI::Baby }
    it "works for any resource that decends from OandaAPI::ResourceBase" do
      expect(baby_klass).to be OandaAPI::Baby
      expect(OandaAPI::ResourceBase.class_from_symbol(:baby)).to be baby_klass
    end
  end

  describe ".labs_resource?" do
    it "is true for a 'Labs' resource" do
      expect(OandaAPI::ResourceBase.labs_resource?(OandaAPI::Resource::Labs::CalendarEvent)).to be true
    end

    it "is false for a non 'Labs' resource" do
      expect(OandaAPI::ResourceBase.labs_resource?(OandaAPI::Resource::Account)).to be false
    end

    let(:flux_capacitor_klass) { module OandaAPI; module Resource; module Labs; module RocketScience class FluxCapacitor < OandaAPI::ResourceBase; end; end; end; end; end; OandaAPI::Resource::Labs::RocketScience::FluxCapacitor }
    it "works for any resource under the Labs:: namespace" do
      expect(flux_capacitor_klass).to be OandaAPI::Resource::Labs::RocketScience::FluxCapacitor
      expect(OandaAPI::ResourceBase.labs_resource?(flux_capacitor_klass)).to be true
    end
  end

  describe ".pluralize" do
    it "pluralizes resource class names" do
      expect(OandaAPI::ResourceBase.pluralize(:account)).to eq "accounts"
    end

    it "doesn't pluralize resource name exceptions (these are never pluralized in the API)" do
      OandaAPI::ResourceBase::NOT_PLURALIZED.each do |special_case_resource|
        expect(OandaAPI::ResourceBase.pluralize(special_case_resource)).to eq special_case_resource.to_s
      end
    end
  end

  describe "#initialize" do
    it "initializes writer methods with matching attributes" do
      obj = SomeResource.new webbed_feet: "webbed feet"
      expect(obj.webbed_feet).to eq "webbed feet"
    end

    it "initializes snake_case writer methods with matching camelCase attributes" do
      obj = SomeResource.new webbedFeet: "webbed feet"
      expect(obj.webbed_feet).to eq "webbed feet"
    end
  end

  describe "#location" do
    it "sets location" do
      obj = SomeResource.new location: "location"
      expect(obj.location).to eq "location"
    end
  end

  describe "#to_json" do
    it "serializes all of an instance's attributes" do
      obj = SomeResource.new webbedFeet: "webbed feet", location: "location", extraAttribute: "extra"
      h = JSON.parse obj.to_json
      expect(h).to include("webbed_feet" => "webbed feet", "extra_attribute" => "extra", "location" => "location")
    end

    it "serializes all of an instance's customized attributes" do
      obj = SomeResourceCustomized.new webbedFeet: "webbed feet"
      h = JSON.parse obj.to_json
      expect(h).to include("webbed_feet" => "customized webbed feet")
    end

    it "serializes when nested" do
      obj = SomeResourceCustomized.new webbedFeet: "webbed feet"
      a = JSON.parse [obj].to_json
      expect(a.first).to include("webbed_feet" => "customized webbed feet")
    end
  end
end
