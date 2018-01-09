module OandaAPI
  module Resource
    # Transaction value object.
    # See the Oanda Developer Guide for information about {http://developer.oanda.com/rest-live/transaction-history/ Transactions}.
    class Transaction < ResourceBase
      attr_accessor :account_balance,
                    :account_id,
                    :amount,
                    :expiry,
                    :id,
                    :instrument,
                    :interest,
                    :lower_bound,
                    :margin_rate,
                    :order_id,
                    :pl,
                    :price,
                    :rate,
                    :reason,
                    :side,
                    :stop_loss_price,
                    :stop_loss_price,
                    :take_profit_price,
                    :time,
                    :trade_id,
                    :trade_opened,
                    :trade_reduced,
                    :trailing_stop_loss_distance,
                    :type,
                    :units,
                    :upper_bound

      def initialize(attributes = {})
        self.trade_opened  = {}
        self.trade_reduced = {}
        super
      end

      def expiry=(v)
        @expiry = Time.parse v.to_s
      end

      def time=(v)
        @time = Time.parse v.to_s
      end

      def trade_opened=(v)
        @trade_opened = TradeOpened.new v
      end

      def trade_reduced=(v)
        @trade_reduced = TradeReduced.new v
      end

      # See http://developer.oanda.com/rest-live/transaction-history/ for attribute details.
      class TradeOpened < ResourceBase
        attr_accessor :id, :units
      end

      # See http://developer.oanda.com/rest-live/transaction-history/ for attribute details.
      class TradeReduced < ResourceBase
        attr_accessor :id, :interest, :pl, :units
      end
    end
  end
end
