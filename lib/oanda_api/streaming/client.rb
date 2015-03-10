module OandaAPI
  module Streaming
    # Resource URI templates
    BASE_URI = {
      live:     "https://stream-fxtrade.oanda.com/[API_VERSION]",
      practice: "https://stream-fxpractice.oanda.com/[API_VERSION]"
    }

    # @example Example usage
    #   client = OandaAPI::Streaming::Client.new :practice, ENV.fetch("ONADA_PRACTICE_TOKEN")
    #
    #   Note: This code will block because streaming is an infinite loop.
    #   prices = client.prices(account_id: 1234, instruments: %w[AUD_CAD AUD_CHF])
    #   prices.stream do |price|
    #
    #     # Note: The code in this block should handle the price
    #     # as efficently as possible, otherwise the connection could timeout.
    #     # For example, you could publish the tick on a queue to be handled
    #     # by some other thread or process.
    #     price  # => OandaAPI::Resource::Price
    #   end
    #
    #   client.events.stream do |transaction|
    #     transaction # => OandaAPI::Resource::Transaction
    #   end
    #
    #   Stopping the stream.
    #   You may add a second argument to the block that yields the client itself.
    #   # Stop after collecting 10 prices
    #
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
    #   @return [Streaming::Client::StreamingRequest]
    #
    # @!attribute [rw] domain
    #   @return [Symbol] identifies the Oanda subdomain (+:practice+ or +:live+)
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

      # Returns +true+ if emitted resources include heartbeats. Defaults to false.
      # @return [boolean]
      def emit_heartbeats?
        !!@emit_heartbeats
      end

      # Stops streaming.
      # @return [void]
      def stop!
        streaming_request.stop! if running?
      end

      # Returns +true+ if the client is currently streaming.
      # @return [boolean]
      def running?
        !!(streaming_request && streaming_request.running?)
      end

      # @private
      # Executes an http request.
      #
      # @param [Symbol] _method Ignored.
      #
      # @param [String] path the path of an Oanda resource request.
      #
      # @param [Hash] conditions optional parameters that are converted into query
      #   parameters.
      #
      # @yield [OandaAPI:ResourceBase]  See {StreamingRequest.stream}
      #
      # @return [void]
      #
      # @raise [OandaAPI::RequestError] if the API return code is not 2xx.
      # @raise [OandaAPI::RequestDisconnect] if the API disconnects.
      def execute_request(_method, path, conditions = {}, &block)
        Http::Exceptions.wrap_and_check do
          @streaming_request = StreamingRequest.new client: self,
                                                    uri: api_uri(path),
                                                    query: Utils.stringify_keys(conditions),
                                                    headers: OandaAPI.configuration.headers.merge(headers)
          @streaming_request.stream(&block)
          return nil
        end

        rescue Http::Exceptions::HttpException => e
          raise OandaAPI::RequestError, e.message
      end

      private

      # @private
      # Enables method-chaining.
      # @return [Namespace]
      def method_missing(sym, *args)
        OandaAPI::Client::NamespaceProxy.new self, sym, args.first
      end
    end

    # An HTTP 1.1 streaming request. Used to create a persistent connection
    # with the server and continuously download a stream of resource
    # representations. Resources are emitted as +OandaAPI::ResourceBase+
    # instances.
    #
    # @!attribute [rw] client
    # @return [OandaAPI::Streaming::Client] a streaming client instance
    #
    # @!attribute [rw] emit_heartbeats
    # @return [boolean]
    #
    # @!attribute [r] uri
    # @return [URI::HTTPS] a URI instance
    #
    # @!attribute [r] request
    # @return [URI::HTTPS] a URI instance
    class StreamingRequest
      attr_accessor :client, :emit_heartbeats
      attr_reader :uri, :request

      # Creates a +StreamingRequest+ instance.
      # @param [Streaming::Client] client a streaming client instance that can be used to
      #   send signals to an instance of this StreamingRequest.
      # @param [String] uri an absolute URI to the service endpoint.
      # @param [Hash] query a list of query parameters, unencoded. The list
      #   is converted into a query string. See {OandaAPI::Client#query_string_normalizer}.
      # @param [Hash] headers a list of header values that will be sent with the request.
      def initialize(client: nil, uri:, query: {}, headers: {})
        self.client = client.nil? ? self : client
        @uri = URI uri
        @uri.query = OandaAPI::Client.default_options[:query_string_normalizer].call(query)
        @http = Net::HTTP.new @uri.host, 443
        @http.use_ssl = true
        @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        @request = Net::HTTP::Get.new @uri
        headers.each_pair { |pair| @request.add_field(*pair) }
      end

      # Sets the client attribute
      # @param [OandaAPI::Streaming::Client] value
      # @return [void]
      # @raise [ArgumentError] if value is not an OandaAPI::Streaming::Client instance.
      def client=(value)
        fail ArgumentError, "Expecting an OandaAPI::Streaming::Client" unless (value.is_a?(OandaAPI::Streaming::Client) || value.is_a?(OandaAPI::Streaming::StreamingRequest))
        @client = value
      end

      # @return [boolean] true if heatbeats are emitted
      def emit_heartbeats?
        !!@emit_heartbeats
      end

      # Signals the streaming request to disconnect.
      # @return [void]
      def stop!
        @stop_requested = true
      end

      # Returns +true+ if the request has been signalled to terminate. See {#stop}.
      # @return [boolean]
      def stop_requested?
        !!@stop_requested
      end

      # @return [true] if the instance is connected and streaming a response
      def running?
        !!@running
      end

      # Emits a stream of +OandaAPI::ResourceBase+ instances.
      # Note this method runs as an infinite loop and will block indefinitely
      # until either the connection is halted or a {#stop} signal is recieved.
      # @yield [OandaAPI::ResourceBase] resource
      # @return [void]
      def stream(&block)
        @stop_requested = false
        @running = true

        # @http.set_debug_output $stderr

        @http.request(@request) do |response|
          response.read_body do |chunk|
            handle_response(chunk).each do |resource|
              block.call(resource, @client)
              return if stop_requested?
            end
            return if stop_requested?
            sleep 0.01
          end
          # Here is where we should sleep then wait no more than the idle timeout amount
        end
      ensure
        @running = false
        @http.finish if @http.started?
      end

      private

      # @private
      # Converts a raw json response into +OandaAPI::ResourceBase+ instances.
      # @return [Array<OandaAPI::ResourceBase>] depending on the endpoint
      #   that the request is servicing, which is either an array of
      #   +OandaAPI::Resource::Price+ or +OandaAPI::Resource::Transaction+ instances.
      #   If #emit_heartbeats? is +true+, then the instance could be an +OandaAPI::Resource::Heartbeat+
      # @raise [OandaAPI::StreamingDisconnect] if the endpoint was disconnected by server.
      # @raise [OandaAPI::RequestError] if an unexpected resource is returned.
      def handle_response(response)
        response.split("\r\n").map do |json|
          parsed_response = JSON.parse json
          case
          when parsed_response["heartbeat"]
            OandaAPI::Resource::Heartbeat.new parsed_response["heartbeat"] if emit_heartbeats?
          when parsed_response["tick"]
            OandaAPI::Resource::Price.new parsed_response["tick"]
          when parsed_response["transaction"]
            OandaAPI::Resource::Transaction.new parsed_response["transaction"]
          when parsed_response["disconnect"]
            raise OandaAPI::StreamingDisconnect, parsed_response["disconnect"]["message"]
          else
            raise OandaAPI::RequestError, "unknown resource: #{json}"
          end
        end.compact
      end
    end
  end
end
