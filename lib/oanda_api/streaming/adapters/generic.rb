module OandaAPI
  module Streaming
    #
    # Everything related to `Streaming::Adapters`
    module Adapters
      #
      # Uses the JSON library. This parser does not handle multiple json objects in a json stream
      #  unless the objects are separated with whitespace.
      module Generic
        extend self

        # A delimiter for separating multiple json objects in a stream.
        DELIMITER = "<oanda_api::delimiter>"
        MULTI_OBJECT_DELIMITER = "}#{DELIMITER}{"

        # Deserializes a stream of JSON objects.
        # @param [String] string serialized json.
        # @return [Array<Hash>] an array of hashes.
        def parse(string)
          string.strip!
          return [] if string.empty?
          string.gsub(/}\s*{/, MULTI_OBJECT_DELIMITER).split(DELIMITER).map do |json|
            JSON.parse json, symbolize_names: true
          end
        end
      end
    end
  end
end
