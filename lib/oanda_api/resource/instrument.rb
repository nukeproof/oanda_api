module OandaAPI
  module Resource
    # Instrument value object.
    # See the Oanda Developer Guide for information about {http://developer.oanda.com/rest-live/rates/#getInstrumentList Instruments}.
    class Instrument < ResourceBase
      attr_accessor :display_name,
                    :halted,
                    :instrument,
                    :margin_rate,
                    :max_trade_units,
                    :max_trailing_stop,
                    :min_trailing_stop,
                    :pip,
                    :precision

      alias_method :halted?, :halted
      alias_method :name, :instrument
      alias_method :name=, :instrument=
    end
  end
end
