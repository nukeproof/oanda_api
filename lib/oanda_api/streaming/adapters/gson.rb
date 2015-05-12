require 'gson'

module OandaAPI
  module Streaming
    module Adapters
      module Gson
        extend self

        def parse(string)
          string.strip!
          return [] if string.empty?
          [parser.decode(string)].flatten
        end

        private

        def parser
          @parser ||= ::Gson::Decoder.new(symbolize_keys: true)
        end
      end
    end
  end
end
