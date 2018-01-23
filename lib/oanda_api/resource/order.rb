module OandaAPI
  module Resource
    # Order value object.
    # See the Oanda Developer Guide for information about {http://developer.oanda.com/rest-live/orders/ Orders}.
    class Order < ResourceBase
      attr_accessor :expiry,
                    :id,
                    :instrument,
                    :lower_bound,
                    :order_opened,
                    :price,
                    :side,
                    :stop_loss,
                    :take_profit,
                    :time,
                    :trades_closed,
                    :trade_opened,
                    :trade_reduced,
                    :trailing_stop,
                    :type,
                    :units,
                    :upper_bound

      def initialize(attributes = {})
        self.order_opened  = {}
        self.trade_opened  = {}
        self.trade_reduced = {}
        self.trades_closed = []
        super
      end

      def expiry=(v)
        @expiry = Time.parse v.to_s
      end

      def time=(v)
        @time = Time.parse v.to_s
      end

      def order_opened=(v)
        @order_opened = OrderOpened.new v
      end

      def trade_opened=(v)
        @trade_opened = TradeOpened.new v
      end

      def trade_reduced=(v)
        @trade_reduced = TradeReduced.new v
      end

      # See the Oanda Developer Guide for {http://developer.oanda.com/rest-live/orders/ Order} details.
      class OrderOpened < ResourceBase
        attr_accessor :expiry, :id, :lower_bound, :side, :stop_loss,
                      :take_profit, :trailing_stop, :units, :upper_bound

        def expiry=(v)
          @expiry = Time.parse v.to_s
        end
      end

      # See the Oanda Developer Guide for {http://developer.oanda.com/rest-live/orders/ Order} details.
      class TradeOpened < ResourceBase
        attr_accessor :id, :side, :stop_loss, :take_profit, :trailing_stop, :units
      end

      # See the Oanda Developer Guide for {http://developer.oanda.com/rest-live/orders/ Order} details.
      class TradeReduced < ResourceBase
        attr_accessor :id, :interest, :pl, :units
      end
    end
  end
end
