module OandaAPI
  module Resource
    # Calendar value object.
    # See the Oanda Developer Guide for information about {http://developer.oanda.com/rest-live/forex-labs/#calendar Calendar}.
    class Calendar < ResourceBase
      attr_accessor :title,
                    :timestamp,
                    :unit,
                    :currency,
                    :forecast,
                    :region,
                    :previous,
                    :actual,
                    :market
    end
  end
end
