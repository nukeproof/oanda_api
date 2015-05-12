shared_examples_for 'an adapter' do |adapter|

  before{ OandaAPI::Streaming::JsonParser.use adapter }

  describe ".parse" do
    it "deserializes json using symbolized keys" do
      [
        ["{\"a\":[{\"b\":{\"3\":3}}]}", [{ :a => [:b => { :"3" => 3 }] }]],
        ["{\"a\":\"a\"} \r\n ", [{ :a => "a"}]],
        ["", []],
        ["   ", []],
        ["\r\n", []]
        
      ].each do |serialized, deserialized|
        expect(OandaAPI::Streaming::JsonParser.adapter.parse(serialized)).to eq(deserialized)
      end
    end
  end
end
