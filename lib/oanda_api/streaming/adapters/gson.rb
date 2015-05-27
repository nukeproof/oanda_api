require 'gson'

module OandaAPI
  module Streaming
    module Adapters
      #
      # Can be used if the ruby engine (`RUBY_ENGINE`) is jruby. Uses the {https://github.com/avsej/gson.rb gson} gem.
      # Handles streams of multiple JSON objects that may or may not be delimited with whitespace.
      module Gson
        extend self

        # Deserializes a stream of JSON objects.
        # @param [String] string serialized json.
        # @return [Array<Hash>] an array of hashes.
        def parse(string)
          string.strip!
          return [] if string.empty?
          [parser.decode(string)].flatten
        end

        private

        # @private
        # Memoized parser instance.
        def parser
          @parser ||= ::Gson::Decoder.new(symbolize_keys: true)
        end
      end
    end
  end
end
