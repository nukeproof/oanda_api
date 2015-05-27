require 'spec_helper'
describe "OandaAPI::ResourceBase" do
  class MyClass < OandaAPI::ResourceBase
    attr_accessor :webbed_feet
  end

  class MyCustomizedClass < OandaAPI::ResourceBase
    attr_accessor :webbed_feet

    def custom_attributes
      super.merge(webbed_feet: "customized #{webbed_feet}")
    end
  end

  describe "#initialize" do
    it "initializes writer methods with matching attributes" do
      obj = MyClass.new webbed_feet: "webbed feet"
      expect(obj.webbed_feet).to eq "webbed feet"
    end

    it "initializes snake_case writer methods with matching camelCase attributes" do
      obj = MyClass.new webbedFeet: "webbed feet"
      expect(obj.webbed_feet).to eq "webbed feet"
    end
  end

  describe "#location" do
    it "sets location" do
      obj = MyClass.new location: "location"
      expect(obj.location).to eq "location"
    end
  end

  describe "#to_json" do
    it "serializes all of an instance's attributes" do
      obj = MyClass.new webbedFeet: "webbed feet", location: "location", extraAttribute: "extra"
      h = JSON.parse obj.to_json
      expect(h).to include("webbed_feet" => "webbed feet", "extra_attribute" => "extra", "location" => "location")
    end

    it "serializes all of an instance's customized attributes" do
      obj = MyCustomizedClass.new webbedFeet: "webbed feet"
      h = JSON.parse obj.to_json
      expect(h).to include("webbed_feet" => "customized webbed feet")
    end

    it "serializes when nested" do
      obj = MyCustomizedClass.new webbedFeet: "webbed feet"
      a = JSON.parse [obj].to_json
      expect(a.first).to include("webbed_feet" => "customized webbed feet")
    end
  end
end
