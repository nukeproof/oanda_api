require 'yajl'

module OandaAPI
  module Streaming
    module Adapters
      module Yajl
        extend self

        def parse(string)
          results = []
          parser.parse(string) { |hash| results << hash }
          results
        end

        private

        def parser
          @parser ||= ::Yajl::Parser.new(symbolize_keys: true)
        end
      end
    end
  end
end
