module OandaAPI
  module Client
    # A client proxy and method-chaining enabler.
    #
    # @example Example usage
    #   client  = OandaAPI::Client::TokenClient.new :practice, token
    #   account = client.account(1234) # => OandaAPI::Client::NamespaceProxy
    #   account.get                    # => OandaAPI::Resource::Account
    #   account.orders.get             # => OandaAPI::Resource::ResourceCollection
    #
    # @!attribute [rw] conditions
    #   @return [Hash] a collection of parameters that typically specifies
    #     conditions and filters for a resource request.
    #
    # @!attribute [rw] namespace_segments
    #   @return [Array<String>] an ordered list of namespaces, when joined,
    #     creates a path to a resource URI.
    class NamespaceProxy
      attr_accessor :conditions, :namespace_segments

      # @param [OandaAPI::Client] client
      #
      # @param [String] namespace_segment a _segment_ in a resource's URI. An
      #   ordered list of segments, joined, creates a path to a resource URI.
      #
      # @param [Hash] conditions an optional list of parameters that typically
      #   specifies conditions and filters for a resource request. A a _"key"_
      #   or _"id"_ is a condition that identifies a particular resource. If a
      #   key condition is included, it is extracted and added as a namespace
      #   segment. See {#extract_key_and_conditions}.
      def initialize(client, namespace_segment, conditions)
        fail ArgumentError, "expecting an OandaAPI::Client instance" unless 
          client && client.is_a?(OandaAPI::Client) || client.is_a?(OandaAPI::Streaming::Client)
        fail ArgumentError, "expecting a namespace value" if namespace_segment.to_s.empty?

        @client = client
        @conditions = {}
        @namespace_segments = [Utils.pluralize(namespace_segment)]
        extract_key_and_conditions conditions
      end

      # Returns a deep clone of +self+.
      # @return [NamespaceProxy]
      def clone
        ns = self.dup
        ns.conditions = conditions.dup
        ns.namespace_segments = namespace_segments.dup
        ns
      end

      # Returns the namespace (URI path to a resource).
      # @return [String]
      def namespace
        "/" + @namespace_segments.join("/")
      end

      # Extracts a _key_ parameter from the arguments.
      # If a key is found, it's appended to the list namespace segments. Non-key
      # parameters are merged into the {#conditions} collection. A parameter is a
      # key if it's named ":id", or if there is only a single scalar argument.
      #
      # @example "key" parameters
      #  client  = OandaAPI::Client::TokenClient.new :practice, token
      #  account = client.account(1234)                  # 1234 is a _key_ (accountId)
      #  account.namespace                               # => /accounts/1234
      #
      #  order = account.order(instrument: "USD_JPY",
      #                              type: "market",
      #                             units: 10_000,
      #                              side: "buy").create # No key parameters here
      #
      #  position = account.position("USD_JPY").get      # USD_JPY is a key
      #
      # @param conditions either a hash of parameter values, single scalar value, or nil.
      #
      # @return [void]
      def extract_key_and_conditions(conditions)
        key =
          case
          when conditions && conditions.is_a?(Hash)
            @conditions.merge! Utils.rubyize_keys(conditions)
            @conditions.delete :id
          when conditions
            conditions
          end
        @namespace_segments << key if key
      end

      # Executes an API request and returns a resource object, or returns a
      # clone of +self+ for method chaining.
      #
      # @yield [OandaAPI::ResourceBase] if the method is +:stream+.
      #
      # @return [void] if the method is +:stream+.
      #
      # @return [OandaAPI::Client::NamespaceProxy] if the method is used
      #   for chaining.
      #
      # @return [OandaAPI::ResourceBase] if the method is one of the supported
      #   _terminating_ methods (+:create+, +:close+, +:delete+, +:get+, +:update+).
      #
      # @return [OandaAPI::ResourceCollection] if the method is +:get+ and the
      #   API returns a collection of resources.
      def method_missing(sym, *args, &block)
        # Check for terminating method
        if [:create, :close, :delete, :get, :update, :stream].include?(sym)
          @client.execute_request sym, namespace, conditions, &block
        else
          ns = self.clone
          ns.namespace_segments << Utils.pluralize(sym)
          ns.extract_key_and_conditions args.first
          ns
        end
      end
    end
  end
end
