module OandaAPI
  module Resource
    # Price value object.
    # See the Oanda Developer Guide for information about {http://developer.oanda.com/rest-live/rates/#getCurrentPrices Prices}.
    class Price < ResourceBase
      attr_accessor :ask,
                    :bid,
                    :instrument,
                    :time

      def time=(v)
        @time = Time.parse v.to_s
      end
    end
  end
end
