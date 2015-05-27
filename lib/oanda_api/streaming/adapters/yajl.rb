require 'yajl'

module OandaAPI
  module Streaming
    module Adapters
      #
      # Can be used if the ruby engine (`RUBY_ENGINE`) is NOT jruby. Uses the {https://github.com/brianmario/yajl-ruby yajl-ruby} gem.
      # Handles streams of multiple JSON objects that may or may not be delimited with whitespace.
      module Yajl
        extend self

        # Deserializes a stream of JSON objects.
        # @param [String] string serialized json.
        # @return [Array<Hash>] an array of hashes.
        def parse(string)
          results = []
          parser.parse(string) { |hash| results << hash }
          results
        end

        private

        # @private
        # Memoized parser instance.
        def parser
          @parser ||= ::Yajl::Parser.new(symbolize_keys: true)
        end
      end
    end
  end
end
