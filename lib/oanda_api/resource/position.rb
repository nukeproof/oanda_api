module OandaAPI
  module Resource
    # Position value object.
    # See the Oanda Developer Guide for information about {http://developer.oanda.com/rest-live/positions/ Positions}.
    class Position < ResourceBase
      attr_accessor :avg_price,
                    :ids,
                    :instrument,
                    :side,
                    :total_units

      alias_method :price,  :avg_price
      alias_method :price=, :avg_price=
      alias_method :units,  :total_units
      alias_method :units=, :total_units=
    end
  end
end
