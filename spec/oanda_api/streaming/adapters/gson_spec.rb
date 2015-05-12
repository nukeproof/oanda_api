require 'spec_helper'
require 'shared/adapter'
require 'oanda_api/streaming/adapters/gson' if jruby?

describe "OandaAPI::Streaming::Adapters::Gson", :if => jruby? do
  it_behaves_like 'an adapter', described_class
end
