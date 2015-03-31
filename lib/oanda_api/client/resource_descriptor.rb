module OandaAPI
  module Client
    # @private
    # Metadata about a resource request.
    #
    # @!attribute [r] collection_name
    #   @return [Symbol] method name that returns a collection of the resource
    #     from the API response.
    #
    # @!attribute [r] path
    #   @return [String] path of the resource URI.
    #
    # @!attribute [r] resource_klass
    #   @return [Symbol] class of the resource.
    class ResourceDescriptor
      attr_reader :collection_name, :path, :resource_klass

      # Mapper for not "typical" resources.
      #   Key is a resource from the API path.
      #   Value is a hash that can contain "resource_name" from the code and/or
      #   "is_collection" (if true: will force treating response as a collection of resources,
      #   if false: will force treating response as a single resource).
      RESOURCES_MAPPER = {
          alltransactions: { resource_name: 'transaction_history', is_collection: false }
      }

      # Analyzes the resource request and determines the type of resource
      # expected from the API.
      #
      # @param [String] path a path to a resource.
      #
      # @param [Symbol] method an http verb (see {OandaAPI::Client.map_method_to_http_verb}).
      def initialize(path, method)
        @path = path
        path.match(/\/(?<resource_name>[a-z]*)\/?(?<resource_id>\w*?)$/) do |names|
          mapped_resource = RESOURCES_MAPPER[names[:resource_name].to_sym]
          resource_name   = (mapped_resource||{})[:resource_name] || Utils.singularize(names[:resource_name])
          resource_id     = names[:resource_id]
          self.resource_klass = resource_name
          @is_collection      = (mapped_resource||{})[:is_collection]
          @is_collection      = method == :get && resource_id.empty?  if @is_collection.nil?
          @collection_name    = Utils.pluralize(resource_name).to_sym if is_collection?
        end
      end

      # True if the request returns a collection.
      # @return [Boolean]
      def is_collection?
        @is_collection
      end

      private

      # The resource type
      # @param [String] resource_name
      # @return [void]
      def resource_klass=(resource_name)
        klass_symbol = OandaAPI::Utils.classify(resource_name).to_sym
        fail ArgumentError, "Invalid resource" unless OandaAPI::Resource.constants.include?(klass_symbol)
        @resource_klass = OandaAPI::Resource.const_get klass_symbol
      end
    end
  end
end
