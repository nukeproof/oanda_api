module OandaAPI
  module Streaming
    # An HTTP 1.1 streaming request. Used to create a persistent connection
    #   with the server and continuously download a stream of resource
    #   representations. Resources are emitted as {OandaAPI::ResourceBase}
    #   instances.
    #
    # @!attribute [rw] client
    #   @return [OandaAPI::Streaming::Client] a streaming client instance.
    #
    # @!attribute [rw] emit_heartbeats
    #   @return [boolean]
    #
    # @!attribute [r] uri
    #   @return [URI::HTTPS] a URI instance.
    #
    # @!attribute [r] request
    #   @return [URI::HTTPS] a URI instance.
    class Request
      attr_accessor :client, :emit_heartbeats
      attr_reader :uri, :request

      # Creates an OandaAPI::Streaming::Request instance.
      # @param [Streaming::Client] client a streaming client instance that can be used to
      #   send signals to an instance of this Streaming::Request.
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
        fail ArgumentError, "Expecting an OandaAPI::Streaming::Client" unless (value.is_a?(OandaAPI::Streaming::Client) || value.is_a?(OandaAPI::Streaming::Request))
        @client = value
      end

      # @return [boolean] true if heatbeats are emitted.
      def emit_heartbeats?
        !!@emit_heartbeats
      end

      # Signals the streaming request to disconnect and terminates streaming.
      # @return [void]
      def stop!
        @stop_requested = true
      end

      # Returns `true` if the request has been signalled to terminate. See {#stop!}.
      # @return [boolean]
      def stop_requested?
        !!@stop_requested
      end

      # @return [true] if the instance is connected and streaming a response.
      def running?
        !!@running
      end

      # Emits a stream of {OandaAPI::ResourceBase} instances, depending
      #  on the endpoint that the request is servicing, either
      #  {OandaAPI::Resource::Price} or {OandaAPI::Resource::Transaction}
      #  instances are emitted. When #emit_heartbeats? is `true`, then
      #  resources could also be {OandaAPI::Resource::Heartbeat}.
      #
      #  Note this method runs as an infinite loop and will block indefinitely
      #  until either the connection is halted or a {#stop!} signal is recieved.
      #
      # @yield [OandaAPI::ResourceBase, OandaAPI::Streaming::Client] Each resource found in the response
      #   stream is yielded as they are received. The client instance controlling the
      #   streaming request is also yielded. It can be used to issue a signaller.#stop! to terminate the resquest.
      # @raise [OandaAPI::StreamingDisconnect] if the endpoint was disconnected by server.
      # @raise [OandaAPI::RequestError] if an unexpected resource is returned.
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
        end
      ensure
        @running = false
        @http.finish if @http.started?
      end

      private

      # @private
      # Converts a raw json response into {OandaAPI::ResourceBase} instances.
      # @return [Array<OandaAPI::ResourceBase>] depending on the endpoint
      #   that the request is servicing, which is either an array of
      #   {OandaAPI::Resource::Price} or {OandaAPI::Resource::Transaction} instances.
      #   When #emit_heartbeats? is `true`, then the instance could be an {OandaAPI::Resource::Heartbeat}.
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
