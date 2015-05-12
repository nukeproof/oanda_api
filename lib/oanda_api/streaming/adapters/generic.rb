module OandaAPI
  module Streaming
    module Adapters
      module Generic
        extend self
        #
        #  Note: This parser assumes that the serialized json objects
        #  are delimited with \r\n.
        def parse(string)
          string.strip!
          return [] if string.empty?
          string.split("\r\n").map { |json| JSON.parse json, symbolize_names: true }
        end
      end
    end
  end
end
