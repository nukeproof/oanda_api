module OandaAPI
  module Resource
    # Heartbeat returned by the Streaming API.
    # See the Oanda Developer Guide for information about {http://developer.oanda.com/rest-live/streaming/ Heartbeats}.
    class Heartbeat < ResourceBase
      attr_accessor :time

      def time=(v)
        @time = Time.parse v.to_s
      end
    end
  end
end
