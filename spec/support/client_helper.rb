require 'support/vcr'

module ClientHelper
  # Returns a practice API client
  def self.client
    @client ||= OandaAPI::Client::TokenClient.new :practice, test_account_token
  end

  def self.test_account_token
    ENV.fetch("OANDA_API_TESTING_TOKEN") do 
       fail(ArgumentError, <<-END
            ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            +  Missing Authentication Token for testing.                     +
            +                                                                +
            +  A test you are running is attempting to create a new          +
            +  testing fixture by making an API request to the Oanda         +
            +  Practice API. Normally this is ONLY required when adding      +
            +  a new API endpoint. Running existing tests do not require     +
            +  this.                                                         +
            +                                                                +
            +  To create new VCR cassette fixtures for the test suite:       +
            +   1. You need to have an Oanda Practice account. (See:         +
            +      https://fxtrade.oanda.com/your_account/fxtrade/register/) +
            +   2. Define OANDA_API_TESTING_TOKEN as an environment          +
            +      variable, setting its value to the authentication         +
            +      token for your Oanda Practice account.                    +
            +   3. Run the tests. You can examine the VCR test fixures       +
            +      that were created in /spec/fixtures/vcr_cassettes.        +
            +      There will not be any reference to your authentication    +
            +      token in the fixture.                                     +
            ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            END
       )
    end
  end

  # A collection of accounts
  def self.accounts
    VCR.use_cassette("client_helper_accounts") do
      ClientHelper.client.accounts.get
    end
  end

  # Returns an account namespace for the client
  def self.account
    client.account(accounts.first.account_id)
  end

  def self.account_id
    accounts.first.account_id
  end

  # Creates a trade
  def self.create_trade(instrument: "USD_JPY",
                              type: "market",
                              side: "buy",
                             units: 10_000,
                             price: nil,
                            expiry: (Time.now + 3600).utc.to_datetime.rfc3339)
    opts =
      case type
      when "market"
        { instrument: instrument,
                type: type,
                side: side,
               units: units }
      when "limit"
        { instrument: instrument,
                type: type,
                side: side,
               units: units,
               price: price,
              expiry: expiry }
      else
        fail ArgumentError, "invalid order type: #{type}"
      end
      
    account.order(opts).create
  end

  singleton_class.send(:alias_method, :create_order, :create_trade)

  # Returns a lightweight instrument object
  def self.instrument(instrument)
    VCR.use_cassette("instrument_#{instrument}") do
      price = ClientHelper.client.prices(instruments: instrument).get.first
      o = Struct.new(:instrument, :bid, :ask).new
      o.instrument = instrument
      o.bid = price.bid
      o.ask = price.ask
      o
    end
  end
end
