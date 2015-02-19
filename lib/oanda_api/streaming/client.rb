module OandaAPI
  module Streaming

    # Resource URI templates
    BASE_URI = {
      live:     "https://stream-fxtrade.oanda.com/[API_VERSION]",
      practice: "https://stream-fxpractice.oanda.com/[API_VERSION]"
    }


    # Example Usage:
    #  client = OandaAPI::Streaming::Client.new :practice, ENV['practice_token']
    #
    #  Note: This code will block since the streaming runs in a loop.
    #        You should probably use this in a threaded application or
    #        a daemon process.
    #        See the documentation for streaming for an example that
    #        uses Celluloid for threading.
    # prices = client.prices(account: 1234, instruments: %w[AUD_CAD AUD_CHF])
    # 
    # prices.stream do |price|
    #
    #    # Note the code this block should not block and handle the tick
    #    # as efficently as possible, otherwise [what would happen?].
    #    # For example, you could publish the tick on a queue to be handled
    #    # by some other thread or process.
    #    price  # => OandaAPI::Resource::Price
    #  end
    #
    # client.events.stream do |transaction|
    #   transaction # => OandaAPI::Resource::Transaction
    # end
    #
    
    
    # Need:  
    #  NamespaceProxy
    #  Query string formatting
    #  HTTP Error wrapping
    #  
    #  Configuration.streaming_connect_retry_strategy = [1,2,5,10,15,30,60,120,:fatal]
    #  Configuration.streaming_disconnect_on_idle_strategy = [10,10] # disconnect if no data for more than 10 seconds, re-connect after waiting 10 seconds
    #  Would would need a read_timeout error to trigger sleep and retry using the streaming_disconnect_on_idle_strategy.
    #
   
require 'pry'
      
    class Client

      attr_reader :auth_token
      attr_accessor :domain, :default_params, :headers

      # @param [Symbol] domain see {#domain}
      # @param [String] auth_token see {#auth_token}
      def initialize(domain, auth_token)
        super()
        @auth_token = auth_token
        self.domain = domain
        @headers = auth
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

      # @private
      # Executes an http request.
      #
      # @param [Symbol] method a request action. See {Client.map_method_to_http_verb}.
      #
      # @param [String] path the path of an Oanda resource request.
      #
      # @param [Hash] conditions optional parameters that are converted into query
      #   parameters.
      #
      # @return [OandaAPI::ResourceBase] See {OandaAPI::Resource} for a list of
      #   resource types that can be returned.
      #
      #
      # @raise [OandaAPI::RequestError] if the API return code is not 2xx.
      def execute_request(method, path, conditions = {}, &block)
        response = Http::Exceptions.wrap_and_check do
          request = StreamingRequest.new uri: api_uri(path),
                                         query: Utils.stringify_keys(conditions),
                                         headers: OandaAPI.configuration.headers.merge(headers)
          request.stream(&block)
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
    # with the server and continuously transfer (by Transfer-Encoding : "chunked")
    # resourse instances.
    #
    # @!attribute [r] uri
    # @return [URI::HTTPS] a URI instance
    class StreamingRequest
      attr_reader :uri

      # Creates a +StreamingRequest+ instance.
      # @param [String] uri an absolute URI to the service endpoint.
      # @param [Hash] query a list of query parameters, unencoded. The list
      #   is converted into a query string. See {OandaAPI::Client#query_string_normalizer}.
      # @param [Hash] headers a list of header values that will be sent with the request.
      def initialize(uri:, query: {}, headers: {})
        @uri = URI uri
        @uri.query = OandaAPI::Client.default_options[:query_string_normalizer].call(query)
        @http = Net::HTTP.new @uri.host, 443
        @http.use_ssl = true
        @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        @request = Net::HTTP::Get.new @uri
        headers.each_pair { |pair| @request.add_field(*pair) }
      end

      # Signals the streaming request to disconnect.
      # @return [void]
      def stop
        @stop_requested = true
      end

      # Returns +true+ if the request has been signalled to terminate. See {#stop}.
      # @return [boolean]
      def stop_requested?
        @stop_requested
      end

      # Emits a stream of +OandaAPI::ResourceBase+ instances.
      # @yield [OandaAPI::ResourceBase] resource
      # @return [void]
      def stream(&block)
        @stop_requested = false

@http.set_debug_output $stderr

        @http.request(@request) do |response|
          response.read_body do |chunk|
# binding.pry
            handle_response(chunk).each do |resource|
              block.call resource
            end
            break if stop_requested?
            sleep 0.01
          end
          # Here is where we should sleep then wait no more than the idle timeout amount
          break  # Why is this needed? 
        end
      end

      private

      # @private
      # Converts a raw json response into +OandaAPI::ResourceBase+ instances.
      # @return [Array<OandaAPI::ResourceBase>] depending on the endpoint
      #   that the request is servicing, this returns an array of
      #   +OandaAPI::Resource::Price+ or +OandaAPI::Resource::Transaction+ instances.
      # @raise [OandaAPI::StreamingDisconnect] if the endpoint was disconnected by server.
      # @raise [OandaAPI::Error] if an unexpected resource is returned.
      def handle_response(response)
         response.split("\r\n").map do |json|
           parsed_response = JSON.parse json
           case
           when parsed_response["heartbeat"]
             # Ignore heartbeats
           when parsed_response["tick"]
             OandaAPI::Resource::Price.new parsed_response["tick"]
           when parsed_response["transaction"]
             OandaAPI::Resource::Transaction.new parsed_response["transaction"]
           when parsed_response["disconnect"]
             Raise OandaAPI::StreamingDisconnect, parsed_response["disconnect"]["message"]
           else
             Raise OandaAPI::Error, "unknown resource", response
           end
         end.compact
      end
    end
  end
end