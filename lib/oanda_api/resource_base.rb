module OandaAPI
  require 'json'

  # Base class for all Resources.
  #
  # @!attribute [rw] location
  #   @return [String] the `location` header if one is returned in an API
  #     response.
  #   @example Using the `location` attribute
  #      client = OandaAPI::Client::TokenClient.new :practice, token
  #      all_transactions = client.account(123).alltransactions.get
  #      all_transactions.location # => https://fxtrade.oanda.com/transactionhistory/d3aed6823c.json.zip
  class ResourceBase
    attr_accessor :location

    # @param [Hash] attributes collection of resource attributes. See the
    #   {http://developer.oanda.com/rest-live/development-guide/ Oanda Developer Guide}
    #   for documentation about resource attributes.
    def initialize(attributes = {})
      initialize_attributes Utils.rubyize_keys(attributes)
      @location = attributes.location if attributes.respond_to? :location
    end

    # Serializes an instance as JSON.
    # @return [String] a stringified JSON representation of an instance
    def to_json(*args)
      JSON.generate @_attributes.merge(custom_attributes), *args
    end

    # Returns the class of a Resource if klass_symbol is the name
    #   of a resource, otherwise nil.
    #
    #   @example Example:
    #     ResourceBase.class_from_symbol(:transaction_history) => OandaAPI::Resource::TransactionHistory
    #     ResourceBase.class_from_symbol(:calendar_event) => OandaAPI::Resource::Labs::CalendarEvent
    #
    # @param [Symbol] resource_symbol symbolized resource name
    #
    # @return [Nil] if resource_symbol is not a Resource.
    #
    # @return [Class] if resource_symbol is identifies a Resource.
    def self.class_from_symbol(resource_symbol)
      descendant resource_symbol
    end

    # Tests whether a class is a Labs Resource.
    #
    # @param [Class] klass the class to be tested.
    #
    # @return [Boolean] True if the class is a Labs Resource.
    def self.labs_resource?(klass)
      (@lab_resources ||=[]).include? klass
    end

    # List of API resources that don't follow normal REST naming standards,
    #  and are not pluralized despite being collections.
    NOT_PLURALIZED = [:calendar]

    # Returns a pluralized version of the resource class name
    # @param [Symbol] klass_symbol
    # @return [String] the pluralized resource class name
    def self.pluralize(klass_symbol)
      NOT_PLURALIZED.include?(klass_symbol.to_sym) ? klass_symbol.to_s : OandaAPI::Utils.pluralize(klass_symbol)
    end

    private

    # @private
    # Called whenever ResourceBase class is inherited by a descendant class.
    #  Used to track descendant classes.
    #  Used to identify classes within the "::Labs::" namespace.
    def self.inherited(klass)
      ResourceBase.inherited(klass) unless self == OandaAPI::ResourceBase
      klass.to_s.match(/^(?<labs>(.*::)?Labs::)?(.*?)?(?<resource_name>(\w)+)$/) do |matched|
        resource_symbol = OandaAPI::Utils.underscore(matched[:resource_name]).to_sym
        (@descendants ||= {})[resource_symbol] = klass
        (@lab_resources ||= []) << klass if matched[:labs]
      end
    end

    # @private
    # Initializes attributes.
    #
    # @param [Hash] attributes collection of resource attributes.
    # @return [void]
    def initialize_attributes(attributes)
      @_attributes = attributes
      attributes.each do |key, value|
        send("#{key}=", value) if respond_to? key
      end
    end

    # @private
    # Provides additional attributes used in serialization.
    # @return [Hash] a hash of customized attributes for serialization
    def custom_attributes
      {}.tap { |hash| hash[:location] = location if location }
    end

    # @private
    # Returns a class name if klass_symbol is the name of a class that
    # descends from {OandaAPI::ResourceBase}, otherwise nil.
    # @param [Symbol] klass_symbol class name of a resource class
    # @return [Class]
    # @return [Nil] if klass_symbol is not a class that descends from
    #  {OandaAPI::ResourceBase}.
    def self.descendant(klass_symbol)
      (@descendants || {})[klass_symbol]
    end
  end
end
