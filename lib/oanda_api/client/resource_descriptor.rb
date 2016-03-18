module OandaAPI
  module Client
    # @private
    # Metadata about a resource request.
    #
    # @!attribute [r] collection_name
    #   @return [Symbol] method name that returns a collection of the resource
    #     from the API response.
    #
    # @!attribute [r] conditions
    #   @return [Hash] a hash of conditions that are required by the resource.
    #
    # @!attribute [r] path
    #   @return [String] path of the resource URI.
    #
    # @!attribute [r] resource_klass
    #   @return [Symbol] class of the resource.
    class ResourceDescriptor

      attr_reader :collection_name, :conditions, :path, :resource_klass

      # Mapper for not "typical" resources.
      #   Key is a resource from the API path.
      #   Value is a hash that can contain: 1) :resource_name which is the OandaAPI ruby resource name and/or
      #   2) :is_collection (if true: response treated as a collection,
      #   false: response treated as a singular resource) and/or
      #   3) :api_resource_name the actual API resource name and/or
      #   4) :conditions a hash of conditions that are required by the resource
      RESOURCES_MAPPER = {
          alltransactions: { resource_name: "transaction_history", is_collection: false },
          calendar:        { resource_name: "calendar_event",      is_collection: true },
          calendar_events: { resource_name: "calendar_event",      is_collection: true,  api_resource_name: "calendar" },
          spreads:         { resource_name: "spread_history",      is_collection: false, api_resource_name: "spreads" },
          spread_historys: { resource_name: "spread_history",      is_collection: false, api_resource_name: "spreads" },
          signals:         { resource_name: "signal",              is_collection: true,  api_resource_name: "signal/autochartist" },
          key_levels:      { resource_name: "key_level",           is_collection: true,  api_resource_name: "signal/autochartist", collection_name: "signals", conditions: { type: "keylevel" } }
      }

      # Analyzes the resource request and determines the type of resource
      # expected from the API.
      #
      # @param [String] path a path to a resource.
      #
      # @param [Symbol] method an http verb (see {OandaAPI::Client.map_method_to_http_verb}).
      def initialize(path, method)
        @path = path
        path.match(/\/(?<resource_name>[a-z_]*)\/?(?<resource_id>\w*?)$/) do |names|
          initialize_from_resource_name(names[:resource_name], method, names[:resource_id])
        end
      end

      # True if the request returns a collection.
      # @return [Boolean]
      def is_collection?
        @is_collection
      end

      # True if the resource represented by the path is one found in the "Labs"
      #  resources in the API.
      #  See {http://developer.oanda.com/rest-live/forex-labs/ Forex Labs} for
      #  details on Labs resources.
      def labs?
        OandaAPI::ResourceBase.labs_resource? resource_klass
      end

      private

      # The resource type
      # @param [String] resource_name
      # @return [void]
      def resource_klass=(resource_name)
        @resource_klass = OandaAPI::ResourceBase.class_from_symbol resource_name.to_sym
        fail ArgumentError, "Invalid resource: #{resource_name}" unless @resource_klass
      end

      # Will set instance attributes based on resource_name, method and resource_id.
      #
      # @param [String] resource_name name of the resource (from the path).
      # @param [Symbol] method an http verb (see {OandaAPI::Client.map_method_to_http_verb}).
      # @param [Symbol] resource_id id of the resource.
      # @return [void]
      def initialize_from_resource_name(resource_name, method, resource_id)
        mapped_resource = RESOURCES_MAPPER.fetch(resource_name.to_sym, { resource_name: Utils.singularize(resource_name) })
        self.resource_klass = mapped_resource.fetch :resource_name
        @is_collection = mapped_resource.fetch :is_collection, method == :get && resource_id.empty?
        @collection_name = mapped_resource.fetch(:collection_name, ResourceBase.pluralize(mapped_resource.fetch(:resource_name)).to_sym) if is_collection?
        # @collection_name    = ResourceBase.pluralize(mapped_resource.fetch(:resource_name)).to_sym if is_collection?
        @conditions = mapped_resource.fetch(:conditions, {})

        # If resource is using an alias name, replace it with its real API resource name.
        @path.sub!(/\w*$/, mapped_resource[:api_resource_name]) if mapped_resource[:api_resource_name]
      end
    end
  end
end
