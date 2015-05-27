module OandaAPI
  module Client
    #
    # Overrides the default JSON parser to symbolize names.
    class JsonParser < HTTParty::Parser
      SupportedFormats = {"application/json" => :json}

      protected

      # perform json parsing on body
      def json
        JSON.parse body, symbolize_names: true
      end
    end
  end
end
