module OandaAPI
  module Streaming
    #
    # Everything related to `Streaming::Adapters`
    module Adapters
      #
      # Uses the JSON library. This parser does not handle multiple json objects in a json stream
      #  unless the objects are separated consistently with a delimiter.
      module Generic
        extend self

        # Delimiter that separates multiple json objects in a stream.
        DELIMITER = "\r\n"

        # Deserializes a stream of JSON objects.
        # @param [String] string serialized json.
        # @return [Array<Hash>] an array of hashes.
        def parse(string)
          string.strip!
          return [] if string.empty?
          string.split(DELIMITER).map { |json| JSON.parse json, symbolize_names: true }
        end
      end
    end
  end
end
