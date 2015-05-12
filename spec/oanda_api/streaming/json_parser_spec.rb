require 'spec_helper'

describe "OandaAPI::Streaming::JsonParser" do

  context "when no streaming json parsers are available" do
    around do |example|
      simulate_no_adapters{ example.call }
    end

    it "defaults to :generic adapter" do
      silence_warnings do
        expect(OandaAPI::Streaming::JsonParser.default_adapter).to eq(:generic)
      end
    end

    it "prints a warning about using a non-optimal JSON parser" do
      expect(Kernel).to receive(:warn).with(/warning/i)
      OandaAPI::Streaming::JsonParser.default_adapter
    end
  end

  it "defaults to the best available JSON parser" do

    # Clear memoized variable that may have already set by previous tests
    OandaAPI::Streaming::JsonParser.send(:remove_instance_variable, :@adapter) if OandaAPI::Streaming::JsonParser.instance_variable_defined?(:@adapter)

    if jruby?
      expect(OandaAPI::Streaming::JsonParser.adapter.to_s).to eq("OandaAPI::Streaming::Adapters::Gson")
    else
      expect(OandaAPI::Streaming::JsonParser.adapter.to_s).to eq("OandaAPI::Streaming::Adapters::Yajl")
    end
  end

  describe "explicitly overriding the adapter" do
    after(:each) do
      OandaAPI::Streaming::JsonParser.adapter = nil
    end
    
    it 'is settable via a symbol' do
      OandaAPI::Streaming::JsonParser.use :generic
      expect(OandaAPI::Streaming::JsonParser.adapter).to eq(OandaAPI::Streaming::Adapters::Generic)
    end

    it 'is settable via a case-insensitive string' do
      OandaAPI::Streaming::JsonParser.use 'generic'
      expect(OandaAPI::Streaming::JsonParser.adapter).to eq(OandaAPI::Streaming::Adapters::Generic)
    end

    it 'is settable via a class' do
      adapter = Class.new
      OandaAPI::Streaming::JsonParser.use adapter
      expect(OandaAPI::Streaming::JsonParser.adapter).to eq(adapter)
    end

    it 'is settable via a module' do
      adapter = Module.new
      OandaAPI::Streaming::JsonParser.use adapter
      expect(OandaAPI::Streaming::JsonParser.adapter).to eq(adapter)
    end
  end

  it 'throws AdapterError on bad input' do
    expect{ OandaAPI::Streaming::JsonParser.use 'bad adapter' }.to raise_error(OandaAPI::Streaming::AdapterError, /bad adapter/)
  end
end
