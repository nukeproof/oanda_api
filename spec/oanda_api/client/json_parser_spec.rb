require 'spec_helper'

describe "OandaAPI::Client::JsonParser" do

  it "deserializes json using symbolized keys" do
    [
      ["{\"a\":[{\"b\":{\"3\":3}}]}", { :a => [:b => { :"3" => 3 }] }],
       [ "\r\n \r\n     {\"a\":\"a\"} \r\n ", { :a => "a"}]
    ].each do |serialized, deserialized|
      expect(OandaAPI::Client::JsonParser.call serialized, :json).to eq(deserialized)
    end
  end
end
