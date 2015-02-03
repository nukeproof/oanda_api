module OandaAPI
  module Resource
    # Candle value object.
    # See the Oanda Developer Guide for information about {http://developer.oanda.com/rest-live/rates/#retrieveInstrumentHistory Candles}.
    class Candle < ResourceBase
      attr_accessor :close_ask,
                    :close_bid,
                    :close_mid,
                    :complete,
                    :high_ask,
                    :high_bid,
                    :high_mid,
                    :low_ask,
                    :low_bid,
                    :low_mid,
                    :open_ask,
                    :open_bid,
                    :open_mid,
                    :time,
                    :volume

      alias_method :complete?, :complete

      def time=(v)
        @time = Time.parse v.to_s
      end
    end
  end
end
