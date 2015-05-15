require 'spec_helper'
require 'shared/adapter'
require 'oanda_api/streaming/adapters/generic'

describe "OandaAPI::Streaming::Adapters::Generic" do
  it_behaves_like 'an adapter', described_class
end
