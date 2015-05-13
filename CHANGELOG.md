# Change Log

## 0.90

 * Add support for live [Streaming](http://developer.oanda.com/rest-live/streaming/).
 * Add #to_json serialization to resource classes.
 * Fixed Yardoc formatting.

###What's New?
OandaAPI now supports Oanda's streaming API for consuming realtime ticks and account transactions. See the example in the README and have a look at the specs for `OandaAPI::Streaming::Client`. 

## 0.91

 * Fixed JSON serialization for nested ResourceBase instances.
 * Fixed some edge cases that could generate ParseError when parsing streaming JSON.
 * Added support for streaming JSON parsers [yajl-ruby](https://github.com/brianmario/yajl-ruby) and [gson](https://github.com/avsej/gson.rb).
 * Serialized JSON is now deserialized using symbolized names to avoid garbage collection overhead that occurs when strings are used.

###What's New?
As with version 0.90, `OandaAPI::Streaming::Client` will use the JSON gem parser if it is the only JSON parser installed. However, the JSON gem does not support parsing streams of objects very robustly (i.e. it expects complete documents, or the stream to delimit multiple objects consistently). If you are using the streaming API, and install either the [yajl-ruby](https://github.com/brianmario/yajl-ruby) gem (for MRI and Rubinius ruby) or the [gson](https://github.com/avsej/gson.rb) gem (for jruby), then `OandaAPI::Streaming::Client` will use either of those streaming JSON gems for a gain in reliability.
