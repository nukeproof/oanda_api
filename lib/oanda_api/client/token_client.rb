module OandaAPI
  module Client
    # Makes requests to the API.
    # Instances access Oanda's _practice_ or _live_ environments.
    # Most API methods require an account API token to perform requests in the
    # associated environment.
    # See the Oanda Development Guide for information about
    # {http://developer.oanda.com/rest-live/authentication/ obtaining a personal access token from Oanda}.
    #
    # @example Example usage
    #   client = OandaAPI::Client::TokenClient.new :practice, ENV.fetch("OANDA_PRACTICE_TOKEN")
    #
    #   # Get information for an account.
    #   # See http://developer.oanda.com/rest-live/accounts/
    #   account = client.accounts.get.first   # => OandaAPI::Resource::Account
    #
    #   # Get a list of open positions.
    #   # See http://developer.oanda.com/rest-live/positions/
    #   positions = client.account(account.id)
    #                     .positions.get      # => OandaAPI::ResourceCollection
    #
    #
    # @!attribute [r] auth_token
    #   @return [String] Oanda personal access token.
    #
    # @!attribute [rw] domain
    #   @return [Symbol] identifies the Oanda subdomain (`:practice` or `:live`)
    #     accessed by the client.
    #
    # @!attribute [rw] default_params
    #   @return [Hash] parameters that are included with every API
    #     request as either query or url_form encoded parameters.
    #
    # @!attribute [rw] headers
    #   @return [Hash] parameters that are included with every API request
    #     as HTTP headers.
    class TokenClient
      include Client

      attr_reader :auth_token
      attr_accessor :domain, :default_params, :headers

      # @param [Symbol] domain see {#domain}
      # @param [String] auth_token see {#auth_token}
      def initialize(domain, auth_token)
        super()
        @auth_token = auth_token
        @default_params = {}
        self.domain = domain
        @headers = auth

        bind_connection_adapter
      end

      # Parameters used for authentication.
      # @return [Hash]
      def auth
        { "Authorization" => "Bearer #{auth_token}" }
      end

      # @private
      # Sets the domain the client can access. (Testing convenience only).
      # @return [void]
      def domain=(value)
        fail ArgumentError, "Invalid domain" unless OandaAPI::DOMAINS.include? value
        @domain = value
      end
    end
  end
end
