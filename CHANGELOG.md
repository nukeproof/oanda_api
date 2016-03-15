# Change Log

## Head

* 2016-03-15  Now TLS verify_mode is explicitly set to OpenSSL::SSL::VERIFY_PEER instead of relying on underlying library defaults.

* 2016-03-14  Added support for the Oanda Forex Labs Economic Calendar API:

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
