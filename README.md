# OandaAPI
[![Gem Version](https://badge.fury.io/rb/oanda_api.svg)](https://rubygems.org/gems/oanda_api)
[![Code Climate](https://codeclimate.com/github/nukeproof/oanda_api/badges/gpa.svg)](https://codeclimate.com/github/nukeproof/oanda_api)
[![Test Coverage](https://codeclimate.com/github/nukeproof/oanda_api/badges/coverage.svg)](https://codeclimate.com/github/nukeproof/oanda_api)

Access Oanda FX accounts, get market data, trade, build trading strategies using Ruby.
## Synopsis 
OandaAPI is a simple Ruby wrapper for the [Oanda REST API](http://developer.oanda.com/rest-live/introduction/).

This style of API wrapper is typically called a [fluent](http://en.wikipedia.org/wiki/Fluent_interface) interface. The wrapper translates native Ruby objects to and from JSON representations that the API understands.

For example,

```ruby
client = OandaAPI::Client::TokenClient.new(:practice, "practice_account_token") 
account = client.account(12345).get 
```

returns an `OandaAPI::Resource::Account`, with method accessors for all of the [Account](http://developer.oanda.com/rest-live/accounts/) attributes defined by the Oanda API.


## Features

A simple native Ruby reflection of the underlying REST API using Ruby idioms where appropriate.

Enable [Oanda's Best Practices](http://developer.oanda.com/rest-live/best-practices/) recommendations for accessing the API including:

- Secure connections over SSL with always verified certificates
- Persistent connections
- Response compression
- Request rate limiting


Some Examples
-------------

### Getting price quotes
```ruby
require 'oanda_api'

client = OandaAPI::Client::TokenClient.new(:practice, ENV.fetch("OANDA_PRACTICE_TOKEN"))

prices = client.prices(instruments: %w(EUR_USD USD_JPY)).get

prices.each do |p|
  p.instrument       # => "EUR_USD"
  p.ask              # => 1.13781
  p.bid              # => 1.13759
  p.time             # => 2015-01-27 21:01:13 UTC
end
```

### Getting candle information
```ruby
require 'oanda_api'

client = OandaAPI::Client::TokenClient.new(:practice, ENV.fetch("OANDA_PRACTICE_TOKEN"))

candles = client.candles( instrument: "EUR_USD",
                         granularity: "M1",
                       candle_format: "midpoint",
                               start: (Time.now - 3600).utc.to_datetime.rfc3339)
                .get

candles.size         # => 57
candles.granularity  # => "M1"
candles.instrument   # => "EUR_USD"

candles.each do |c|
  c.complete?        # => true
  c.open_mid         # => 1.137155
  c.close_mid        # => 1.137185
  c.high_mid         # => 1.13729
  c.low_mid          # => 1.137155
  c.time             # => 2015-01-27 20:26:00 UTC
  c.volume           # => 25
end
```


### Creating a market order
```ruby
require 'oanda_api'

client = OandaAPI::Client::TokenClient.new(:practice, ENV.fetch("OANDA_PRACTICE_TOKEN"))

order = client.account(12345)
              .order(instrument: "USD_JPY", 
                           type: "market",
                           side: "buy",
                          units: 10_000)
              .create

order.price            # => 114.887
order.time             # => 2014-12-20 21:25:57 UTC
order.trade_opened.id  # => 175491416                         
```

### Closing a position
```ruby
require 'oanda_api'

client = OandaAPI::Client::TokenClient.new(:practice, ENV.fetch("OANDA_PRACTICE_TOKEN"))

account = client.account(12345)             # => OandaAPI::NamespaceProxy
position = account.position("USD_JPY").get  # => OandaAPI::Resource::Position

position.ave_price  # => 114.898
position.side       # => "buy"
position.units      # => 30_000 

# Close out the 30_000 long position
closed_position = account.position("USD_JPY").close  # => OandaAPI::Resource::Position

closed_position.price        # => 114.858
closed_position.total_units  # => 30_000
closed_position.ids          # => [175490804, 175491421, 175491416]

transaction = account.transaction(175490804).get    # => OandaAPI::Resource::Transaction
transaction.instrument  # => "USD_JPY"
transaction.time        # => 2014-12-19 03:29:48 UTC
transaction.type        # => "MARKET_ORDER_CREATE"
```

### Getting Economic Calendar Information

```ruby
require 'oanda_api'

# If you want to use sugar like: 1.day, 1.hour, 1.week, etc.
require 'active_support/core_ext/numeric/time'

client = OandaAPI::Client::TokenClient.new(:practice, ENV.fetch("OANDA_PRACTICE_TOKEN"))

client.calendar(period: 1.day).get.each do |event|
  event.class     # => OandaAPI::Resource::CalendarEvent
  event.title     # => "Industrial Production"
  event.currency  # => "EUR"
  event.region    # => "europe"
  event.forecast  # => "-0.3"
  event.previous  # => "-0.3"
  event.actual    # => "3.3"
  event.impact    # => "2"
  event.unit      # => "% m/m"
  event.timestamp # => 1457420400
  event.time      # => 2016-03-08 07:00:00 UTC
end
```

##Streaming
OandaAPI also supports the [Oanda realtime streaming API](http://developer.oanda.com/rest-live/streaming/).

For example to stream live prices,

```ruby
client = OandaAPI::Streaming::Client.new(:practice, ENV.fetch("OANDA_PRACTICE_TOKEN")) 
prices = client.prices(account_id: 1234, instruments: %w[AUD_CAD AUD_CHF])
prices.stream do |price|
  # Note: The code in this block should handle the price
  #       as efficiently as possible, otherwise the connection could timeout.
  #       For example, you could publish the tick on a queue to be handled
  #       by some other thread or process.
  price  # => OandaAPI::Resource::Price
end 
```


Documentation
-------------

Please see the [Oanda Developer Wiki](http://developer.oanda.com/rest-live/introduction/)
for detailed documentation and API usage notes.


| Ruby                       |  Oanda REST API      |
|:---------------------------|:---------------------|
| client.accounts.get        | GET /v1/accounts     |
| client.account(123).get    | GET /v1/accounts/123 |
| client.instruments(account_id: 123).get     | GET /v1/instruments?accountId=123  |
| client.prices(instruments: ["EUR_USD","USD_JPY"]).get | GET /v1/prices/?instruments=EUR_USD%2CUSD_JPY |
| client.account(123).orders.get | GET /v1/accounts/123/orders |
| client.account(123).order(123).get | GET /v1/accounts/123/orders/123 |
| client.account(123).order( *options* ).create | POST /v1/accounts/123/orders |
| client.account(123).order(id:123, *options* ).update | PATCH /v1/accounts/123/orders/123 |
| client.account(123).order(123).close | DELETE /v1/accounts/123/orders/123 |
| client.account(123).positions.get | GET /v1/accounts/123/positions |
| client.account(123).position("EUR_USD").get | GET /v1/accounts/123/positions/EUR_USD |
| client.account(123).position("EUR_USD").close | DELETE /v1/accounts/123/positions/EUR_USD |
| client.account(123).trades.get | GET /v1/accounts/123/trades |
| client.account(123).trade(123).get | GET /v1/accounts/123/trades/123 |
| client.account(123).trade(id:123, *options* ).update | PATCH /v1/accounts/123/trades/123 |
| client.account(123).trade(123).close | DELETE /v1/accounts/123/trades/123 |
| client.account(123).transactions.get | GET /v1/accounts/123/transactions |
| client.account(123).transaction(123).get | GET /v1/accounts/123/transactions/123 |
| client.account(123).alltransactions.get | GET /v1/accounts/123/alltransactions |
| client.calendar(instrument: "AUD_USD", period: 86400).get | GET /labs/v1/calendar?instrument=AUD_USD&period=86400|
| client.spreads(instrument: "AUD_USD", period: 86400).get | GET /labs/v1/spreads?instrument=AUD_USD&period=86400|



Installation
------------

Add this line to your application's Gemfile:

    gem 'oanda_api'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install oanda_api

Inside of your Ruby program, require oanda_api with:

    require 'oanda_api'

Configuration
-------------

Add a configuration block to your application to specify client settings such
as whether or not to use compression, request rate limiting, or other options.
See the RubyDoc [documentation](http://www.rubydoc.info/gems/oanda_api) for OandaAPI for more configuration settings.

```ruby
OandaAPI.configure do |config|
  config.use_compression = true
  config.use_request_throttling = true
  config.max_requests_per_second = 10
end
```

Supported Platforms
-------------------

OandaAPI works with Ruby 2.0 and higher.

Tested on:

* MRI 2.1, 2.2, 2.3
* JRuby 1.7, 9.0.0.0.pre
* Rubinius 2.4, 2.5

Contributing
------------

If you'd like to contribute code or modify this gem, you can run the test suite with:

```ruby
gem install oanda_api --dev
bundle exec rspec # or just 'rspec' may work
```
When you're ready to code:

1. Fork this repository on github.
2. Make your changes.
3. Add tests where applicable and run the existing tests with `rspec` to make sure they all pass.
4. Add new documentation where appropriate using [YARD](http://yardoc.org/) formatting.
5. Create a new pull request and submit it to me.


License
-------

Copyright (c) 2014 Dean Missikowski. Distributed under the MIT License. See
[LICENSE](LICENSE) for further details.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
