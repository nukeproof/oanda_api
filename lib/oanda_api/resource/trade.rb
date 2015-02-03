module OandaAPI
  module Resource
    # Trade value object.
    # See the Oanda Developer Guide for information about {http://developer.oanda.com/rest-live/trades/ Trades}.
    class Trade < ResourceBase
      attr_accessor :id,
                    :instrument,
                    :price,
                    :profit,
                    :side,
                    :stop_loss,
                    :take_profit,
                    :time,
                    :trailing_amount,
                    :trailing_stop,
                    :units

      def time=(v)
        @time = Time.parse v.to_s
      end
    end
  end
end
