# Change Log

## Head
* 2016-06-06 Fixed request rate throttling to correct calculation of wait times. Prior to this fix, under heavy loads from multiple threads, wait times could be calculated incorrectly and result in excessive delays between requests. Thanks [LifeBCE](https://github.com/lifeBCE)!   
* 2016-04-11 Added support for rate limiting new connections. See [Connection Limits](http://developer.oanda.com/rest-live/best-practices/#connection_limits) for details on limits. Rate limiting is NOT enabled by default. To enable rate limiting:

   ```ruby
		OandaAPI.configure do |config|
		  config.use_request_throttling = true
		  config.max_new_connections_per_second = 1
		end
	```

  `config.use_request_throttling = true` can prevent exceeding Oanda's limit on the rate of creating new connections (you'll receive an HTTP 429 response, and a message stating: "Rate limit violation of newly established connections" if you exceed the limit). Note that this is a completely separate rate limit from the maximum number of requests allowed per second on an established connection (use `config.max_requests_per_second` to configure that).

## 0.9.5
* 2016-03-18 Fixed `OandaAPI::Resource::Order#initialize` to correctly initialize `#order_opened`, `#trade_opened`, `#trade_reduced`, and `#trades_closed` from the response data.

* 2016-03-16 Added support for the Oanda [Forex Labs Spread History](http://developer.oanda.com/rest-live/forex-labs/#spreads) API:

   ```ruby
     require 'oanda_api'
     # If you want to use sugar like: 1.day, 1.hour, 1.week, etc.
     require 'active_support/core_ext/numeric/time'

     client = OandaAPI::Client::TokenClient.new(:practice, ENV.fetch("OANDA_PRACTICE_TOKEN"))
     spreads = client.spreads(instrument: "EUR_USD", period: 1.day).get

     spreads.class                    # OandaAPI::Resource::Labs::SpreadHistory
     spreads.averages.size            # => 94
     spreads.maximums.size            # => 76
     spreads.averages.size            # => 50

     spreads.averages.first.spread    # => 1.81711
     spreads.averages.first.timestamp # => 1458081900
     spreads.averages.first.time      # => 2016-03-15 23:00:00 UTC

     spreads.maximums.first.spread    # => 2.1
     spreads.maximums.first.timestamp # => 1458082800
     spreads.maximums.first.time      # => 2016-03-15 23:00:00 UTC

     spreads.minimums.first.spread    # => 1.6
     spreads.minimums.first.timestamp # => 1458081900
     spreads.minimums.first.time      # => 2016-03-15 23:00:00 UTC
   ```

* 2016-03-16 Fixed `OandaAPI::Streaming::Client#emit_heartbeats=true`. Now heartbeats actually will be emitted if true. Previously this setting was ignored and heartbeats were never emitted. Thanks [dogwood008](https://github.com/dogwood008)!

* 2016-03-15  Now TLS verify_mode is explicitly set to OpenSSL::SSL::VERIFY_PEER instead of relying on underlying library defaults.

* 2016-03-14  Added support for the Oanda [Forex Labs Economic Calendar](http://developer.oanda.com/rest-live/forex-labs/#calendar) API:

  Thanks [unageanu](https://github.com/unageanu)!

   ```ruby
     require 'oanda_api'
     # If you want to use sugar like: 1.day, 1.hour, 1.week, etc.
     require 'active_support/core_ext/numeric/time'

     client = OandaAPI::Client::TokenClient.new(:practice, ENV.fetch("OANDA_PRACTICE_TOKEN"))

     client.calendar_events(period: 1.day).get.each do |event|
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

* 2016-03-14 Deprecated `OandaAPI::Client::UsernameClient`. The `http://api-sandbox.oanda.com/` endpoint that this client used is no longer supported by Oanda. Instead, you can use `OandaAPI::Client::TokenClient` with a practice account.

## 0.9.4

* Added multi-threaded support for request throttling. Now if you've configured the API to use request throttling:

  ```ruby
  OandaAPI.configure do |config|
      config.use_request_throttling = true
      config.max_requests_per_second = 15
  end
  ```
and if you access a single instance of the API from multiple threads, then the request rate will be throttled correctly.

* Added a new configuration to customize the number of connections the API holds in the connection pool. Useful if your application requires multiple connections to the API, for example multiple threads issuing requests through the API. The default connection pool size is 2.

   ```ruby
   OandaAPI.configure do |config|
      config.connection_pool_size = 5
  end
   ```
Thanks [LifeBCE](https://github.com/lifeBCE)!

## 0.9.3

* Fixed support for retrieving [full account history](http://developer.oanda.com/rest-live/transaction-history/#getFullAccountHistory). Thanks [bewon](https://github.com/bewon)!
* Fixed issue [#6](https://github.com/nukeproof/oanda_api/issues/6) to make streaming JSON parsers available correctly under *nix. Thanks [LifeBCE](https://github.com/lifeBCE)!

## 0.9.2

 * Specify version of HTTParty as 0.13.3 until HTTParty issue [#398](https://github.com/jnunemaker/httparty/issues/398) is resolved.
 * Now support any whitespace as delimiting multiple JSON objects in streaming API with `OandaAPI::Streaming::Adapters::Generic`.

## 0.9.1

 * Fixed JSON serialization for nested ResourceBase instances.
 * Fixed some edge cases that could generate ParseError when parsing streaming JSON.
 * Added support for streaming JSON parsers [yajl-ruby](https://github.com/brianmario/yajl-ruby) and [gson](https://github.com/avsej/gson.rb).
 * Serialized JSON is now deserialized using symbolized names to avoid garbage collection overhead that occurs when strings are used.

###What's New?
As with version 0.9.0, `OandaAPI::Streaming::Client` will use the JSON gem parser if it is the only JSON parser installed. However, the JSON gem does not support parsing streams of objects very robustly (i.e. it expects complete documents, or the stream to delimit multiple objects consistently). If you are using the streaming API, and install either the [yajl-ruby](https://github.com/brianmario/yajl-ruby) gem (for MRI and Rubinius ruby) or the [gson](https://github.com/avsej/gson.rb) gem (for jruby), then `OandaAPI::Streaming::Client` will use either of those streaming JSON gems for a gain in reliability.

## 0.9.0

 * Add support for live [Streaming](http://developer.oanda.com/rest-live/streaming/).
 * Add #to_json serialization to resource classes.
 * Fixed Yardoc formatting.

###What's New?
OandaAPI now supports Oanda's streaming API for consuming realtime ticks and account transactions. See the example in the README and have a look at the specs for `OandaAPI::Streaming::Client`.
