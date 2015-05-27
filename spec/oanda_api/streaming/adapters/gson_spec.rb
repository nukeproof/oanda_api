require 'spec_helper'
require 'shared/adapter'
require 'oanda_api/streaming/adapters/gson' if gem_installed? :Gson

describe "OandaAPI::Streaming::Adapters::Gson", :if => gem_installed?(:Gson) do
  it_behaves_like 'an adapter', described_class
end
