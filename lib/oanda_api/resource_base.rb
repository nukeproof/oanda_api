module OandaAPI
  # Base class for all Resources.
  #
  # @!attribute [rw] location
  #   @return [String] the +location+ header if one is returned in an API
  #     response.
  #   @example Using the +location+ attribute
  #      client = OandaAPI::Client::TokenClient.new :practice, token
  #      all_transactions = client.account(123).alltransactions.get
  #      all_transactions.location # => https://fxtrade.oanda.com/transactionhistory/d3aed6823c.json.zip
  class ResourceBase
    attr_accessor :location

    # @param [Hash] attributes collection of resource attributes. See the
    #   {http://developer.oanda.com/rest-live/development-guide/ Oanda Developer Guide}
    #   for documentation about resource attributes.
    def initialize(attributes = {})
      initialize_attributes Utils.rubyize_keys(attributes.dup)
      @location = attributes.location if attributes.respond_to? :location
    end

    private

    # @private
    # Initializes attributes.
    #
    # @param [Hash] attributes collection of resource attributes.
    # @return [void]
    def initialize_attributes(attributes)
      attributes.each do |key, value|
        send("#{key}=", value) if respond_to? key
      end
    end
  end
end
