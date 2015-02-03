require 'support/vcr'
module ClientHelper
  # Returns a sandbox client
  def self.client
    VCR.use_cassette("sandbox_client") do
      client = OandaAPI::Client::UsernameClient.new "_"
      new_account = client.account.create
      OandaAPI::Client::UsernameClient.new new_account.username
    end
  end

  # Returns the account namespace for the client
  def self.account
    VCR.use_cassette("sandbox_client_account") do
      account_id = ClientHelper.client.accounts.get.first.account_id
      ClientHelper.client.account(account_id)
    end
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
    VCR.use_cassette("sandbox_instrument_#{instrument}") do
      price = ClientHelper.client.prices(instruments: instrument).get.first
      o = Struct.new(:instrument, :bid, :ask).new
      o.instrument = instrument
      o.bid = price.bid
      o.ask = price.ask
      o
    end
  end
end
