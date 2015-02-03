module OandaAPI
  # A collection of a specific resource. Returned by API requests that return
  # collections. See the {http://developer.oanda.com/rest-live/development-guide/ Oanda Development Guide}
  # for documentation about resource attributes expected for specific requests.
  #
  # @example  Getting candle information
  #   client  = OandaAPI::Client::TokenClient.new :practice, token
  #   candles = client.candles( instrument: "EUR_USD",
  #                            granularity: "M1",
  #                                  count: 1,
  #                          candle_format: "midpoint" ).get
  #
  #   candles              # => OandaAPI::ResourceCollection
  #   candles.granularity  # => "M1"
  #   candles.instrument   # => "EUR_USD"
  #   candles.first        # => OandaAPI::Resource::Candle
  #
  # @!attribute [r] location
  #   @return [String] see {ResourceBase#location}
  class ResourceCollection
    include Enumerable

    attr_reader :location

    # @param [Hash] attributes collection of resource attributes
    #
    # @param [OandaAPI::Client::ResourceDescriptor] resource_descriptor metadata
    #   about the resource collection and its elements.
    def initialize(attributes, resource_descriptor)
      attributes = {} if attributes.nil? || attributes.respond_to?(:empty) && attributes.empty?
      fail ArgumentError, "Expecting a Hash" unless attributes.respond_to? :each_pair
      @attributes = Utils.rubyize_keys attributes
      @collection = @attributes.delete(resource_descriptor.collection_name) || []
      @collection.map! { |resource| resource_descriptor.resource_klass.new resource }
      @location   = attributes.location if attributes.respond_to? :location
    end

    # @yield [OandaAPI::ResourceBase]
    # @return [Enumerator]
    def each
      if block_given?
        @collection.each { |el| yield el }
      else
        @collection.each
      end
    end

    # @private
    # Responds to collection-scoped accessor methods that are specific to the
    # type of resource collection. For example, a +Candle+ collection includes
    # the collection-scoped methods +granularity+ and +instrument+.
    def method_missing(sym, *args)
      case
      when @attributes.keys.include?(sym) 
        @attributes[sym]
      when
        @collection.respond_to?(sym)
          @collection.send sym
      else
        super
      end
    end

    # Returns +true+ for concrete, delegated and dynamic methods.
    # @return [Boolean]
    def respond_to?(sym)
      case
      when @attributes.keys.include?(sym)
        true
      when @collection.respond_to?(sym)
        true
      else
        super
      end
    end
  end
end
