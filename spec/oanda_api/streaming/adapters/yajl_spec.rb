require 'spec_helper'
require 'shared/adapter'
require 'oanda_api/streaming/adapters/yajl' unless jruby?

describe "OandaAPI::Streaming::Adapters::Yajl", :unless => jruby? do
  it_behaves_like 'an adapter', described_class
end
