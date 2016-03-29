module OandaAPI
  # Namespace for all resources.
  module Resource
    # Account value object.
    # See the Oanda Developer Guide for information about {http://developer.oanda.com/rest-live/accounts/ Accounts}.
    class Account < ResourceBase
      attr_accessor :account_currency,
                    :account_id,
                    :account_name,
                    :balance,
                    :margin_available,
                    :margin_rate,
                    :margin_used,
                    :open_orders,
                    :open_trades,
                    :realized_pl,
                    :unrealized_pl

      alias_method :id,  :account_id
      alias_method :id=, :account_id=

      alias_method :currency,  :account_currency
      alias_method :currency=, :account_currency=

      alias_method :name,  :account_name
      alias_method :name=, :account_name=

      def initialize(attributes = {})
        @open_orders = []
        @open_trades = []
        super
      end
      
      # :nocov:
      def password=(v)
        deprecated :password
      end
      
      def password
        deprecated :password
      end

      def username=(v)
        deprecated :username
      end

      def username
        deprecated :username
      end
      # :nocov:
      
      def deprecated (method)
        warn Kernel.caller.first + " [ DEPRECATED ] #{method} has been removed by Oanda"
      end
    end
  end
end
