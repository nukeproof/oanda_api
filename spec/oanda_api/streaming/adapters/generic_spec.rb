require 'spec_helper'
require 'shared/adapter'
require 'oanda_api/streaming/adapters/generic'

describe "OandaAPI::Streaming::Adapters::Generic" do
  it_behaves_like 'an adapter', described_class

  it 'raises parse error when parsing a stream of "undelimited" JSON objects' do
    OandaAPI::Streaming::JsonParser.use :generic
    expect{
      OandaAPI::Streaming::JsonParser.adapter.parse "{:tick=>{:id=>1}} {:tick=>{:id=>1}}"
    }.to raise_error(JSON::ParserError)
  end
end
