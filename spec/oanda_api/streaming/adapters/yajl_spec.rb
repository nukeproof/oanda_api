require 'spec_helper'
require 'shared/adapter'
require 'oanda_api/streaming/adapters/yajl' if gem_installed? :Yajl

describe "OandaAPI::Streaming::Adapters::Yajl", :if => gem_installed?(:Yajl) do
  it_behaves_like 'an adapter', described_class
end
