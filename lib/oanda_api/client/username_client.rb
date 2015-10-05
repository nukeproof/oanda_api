module OandaAPI
  module Client
    # Makes requests to the API.
    # Instances access the Oanda _sandbox_ environment.
    # Most client requests require a valid Oanda sandbox account username.
    # See the Oanda Development Guide for information about
    # {http://developer.oanda.com/rest-live/accounts/#createTestAccount creating a test account}.
    #
    # @example Example usage (creates a new test account).
    #   client = OandaAPI::Client::UsernameClient.new "_"  # Note: A new test account can be created without having an
    #                                                      # existing account, which is why we create a client in this
    #                                                      # example with a bogus username ("_").
    #   new_account = client.account.create                # => OandaAPI::Resource::Account
    #   new_account.username                               # => "<username>"
    #
    #
    # @!attribute [r] domain
    #   @return [Symbol] identifies the Oanda subdomain (`:sandbox`) which the
    #     client accesses.
    #
    # @!attribute [r] username
    #  @return [String] the username used for authentication.
    #
    # @!attribute [rw] default_params
    #   @return [Hash] parameters that are included with every API request as
    #     either query or url_form encoded parameters.
    #
    # @!attribute [rw] headers
    #   @return [Hash] parameters that are included with every API request as
    #     HTTP headers.
    class UsernameClient
      include Client

      attr_reader :domain, :username
      attr_accessor :default_params, :headers

      # @param [String] username used for authentication.
      def initialize(username, options={})
        super options
        @domain = :sandbox
        @username = username
        @default_params = auth
        @headers = {}
      end

      # Parameters used for authentication.
      # @return [Hash]
      def auth
        { "username" => @username }
      end
    end
  end
end
