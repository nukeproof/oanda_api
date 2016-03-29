module OandaAPI
  module Resource
    # Candle value object.
    # See the Oanda Developer Guide for information about {http://developer.oanda.com/rest-live/rates/#retrieveInstrumentHistory Candles}.
    class Candle < ResourceBase

      # Granularity Constants
      # See http://developer.oanda.com/rest-live/rates/#aboutCandlestickRepresentation
      module Granularity
        # Top of minute alignments
        S5  = "S5"
        S10 = "S10"
        S15 = "S15"
        S30 = "S30"
        M1  = "M1"

        # Top of hour alignments
        M2  = "M2"
        M3  = "M3"
        M4  = "M4"
        M5  = "M5"
        M10 = "M10"
        M15 = "M15"
        M30 = "M30"
        H1  = "H1"

        # Start of day alignments (default 17:00, Timezone/New York)
        H2  = "H2"
        H3  = "H3"
        H4  = "H4"
        H6  = "H6"
        H8  = "H8"
        H12 = "H12"
        D   = "D1"

        # Start of week alignment (default Friday)
        W = "W"

        # Start of month alignment (first day of month)
        M = "M"

        VALID_GRANULARITIES = [S5,S10,S15,S30,M1,M2,M3,M4,M5,M10,M15,M30,H1,H2,H3,H4,H6,H8,H12,D,W,M]
      end

      # Candle Formats
      module Format
        BIDASK   = "bidask"
        MIDPOINT = "midpoint"
      end

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
