module OandaAPI
  module Streaming
    # Resource URI templates
    BASE_URI = {
      live:     "https://stream-fxtrade.oanda.com/[API_VERSION]",
      practice: "https://stream-fxpractice.oanda.com/[API_VERSION]"
    }

    # @example Example Usage
    #   client = OandaAPI::Streaming::Client.new :practice, ENV.fetch("ONADA_PRACTICE_TOKEN")
    #
    #   # IMPORTANT
    #   # This code will block indefinitely because streaming executes as an infinite loop.
    #   prices = client.prices(account_id: 1234, instruments: %w[AUD_CAD AUD_CHF])
    #   prices.stream do |price|
    #
    #     # The code in this block should handle the price as efficently
    #     # as possible, otherwise the connection could timeout.
    #     # For example, you could publish the tick on a queue to be handled
    #     # by some other thread or process.
    #     price  # => OandaAPI::Resource::Price
    #   end
    #
    #   client.events.stream do |transaction|
    #     transaction # => OandaAPI::Resource::Transaction
    #   end
    #
    #   # -- Stopping the stream --
    #   # You may add a second argument to the block to yield the client itself.
    #   # You can use it to issue a client.stop! to terminate streaming.
    #   @prices = []
    #   prices = client.prices(account_id: 1234, instruments: %w[AUD_CAD AUD_CHF])
    #   prices.stream do |price, client|
    #     @prices << price
    #     client.stop! if @prices.size == 10
    #   end
    #
    # @!attribute [r] auth_token
    #   @return [String] Oanda personal access token.
    #
    # @!attribute [r] streaming_request
    #   @return [OandaAPI::Streaming::Request]
    #
    # @!attribute [rw] domain
    #   @return [Symbol] identifies the Oanda subdomain (`:practice` or `:live`)
    #     accessed by the client.
    #
    # @!attribute [rw] headers
    #   @return [Hash] parameters that are included with every API request
    #     as HTTP headers.
    class Client
      attr_reader :auth_token, :streaming_request
      attr_accessor :domain, :headers

      # @param [Symbol] domain see {#domain}
      # @param [String] auth_token see {#auth_token}
      def initialize(domain, auth_token)
        super()
        @auth_token = auth_token
        self.domain = domain
        @headers = auth
        @streaming_request = nil
      end

      # Returns an absolute URI for a resource request.
      #
      # @param [String] path the path portion of the URI.
      #
      # @return [String] a URI.
      def api_uri(path)
        uri = "#{BASE_URI[domain]}#{path}"
        uri.sub "[API_VERSION]", OandaAPI.configuration.rest_api_version
      end

      # Parameters used for authentication.
      # @return [Hash]
      def auth
        { "Authorization" => "Bearer #{auth_token}" }
      end

      # @private
      # Sets the domain the client can access.
      # @return [void]
      def domain=(value)
        fail ArgumentError, "Invalid domain" unless OandaAPI::DOMAINS.include? value
        @domain = value
      end

      # Determines whether emitted resources should include heartbeats.
      # @param [boolean] value
      def emit_heartbeats=(value)
        @emit_heartbeats = value
        streaming_request.emit_heartbeats = value if streaming_request
      end

      # Returns `true` if emitted resources include heartbeats. Defaults to false.
      # @return [boolean]
      def emit_heartbeats?
        !!@emit_heartbeats
      end

      # Signals the streaming request to disconnect and terminates streaming.
      # @return [void]
      def stop!
        streaming_request.stop! if running?
      end

      # Returns `true` if the client is currently streaming.
      # @return [boolean]
      def running?
        !!(streaming_request && streaming_request.running?)
      end

      # @private
      # Executes a streaming http request.
      #
      # @param [Symbol] _method Ignored.
      #
      # @param [String] path the path of an Oanda resource request.
      #
      # @param [Hash] conditions optional parameters that are converted into query parameters.
      #
      # @yield [OandaAPI:ResourceBase, OandaAPI::Streaming::Client]  See {OandaAPI::Streaming::Request.stream}
      #
      # @return [void]
      #
      # @raise [OandaAPI::RequestError] if the API return code is not 2xx.
      # @raise [OandaAPI::StreamingDisconnect] if the API disconnects.
      def execute_request(_method, path, conditions = {}, &block)
        Http::Exceptions.wrap_and_check do
          @streaming_request = OandaAPI::Streaming::Request.new client: self,
                                                                uri: api_uri(path),
                                                                query: Utils.stringify_keys(conditions),
                                                                headers: OandaAPI.configuration.headers.merge(headers)
          @streaming_request.emit_heartbeats = emit_heartbeats?
          @streaming_request.stream(&block)
          return nil
        end

        rescue Http::Exceptions::HttpException => e
          raise OandaAPI::RequestError, e.message
      end

      private

      # @private
      # Enables method-chaining.
      # @return [OandaAPI::Client::NamespaceProxy]
      def method_missing(sym, *args)
        OandaAPI::Client::NamespaceProxy.new self, sym, args.first
      end
    end
  end
end
