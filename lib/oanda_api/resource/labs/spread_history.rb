module OandaAPI
  module Resource
    module Labs

    # Spread value object.
    # See the Oanda Developer Guide for information about {http://developer.oanda.com/rest-live/forex-labs/#spreads Spreads}.
      class SpreadHistory < ResourceBase
        attr_accessor :avg,
                      :max,
                      :min

        alias_method :averages, :avg
        alias_method :maximums, :max
        alias_method :minimums, :min

        def initialize(attributes = {})
          attribs = attributes.dup
          self.averages = attribs.delete(:avg) || []
          self.maximums = attribs.delete(:max) || []
          self.minimums = attribs.delete(:min) || []
          super attribs
        end

        def averages=(array=[])
          @avg = []
          array.each { |elements| @avg << Tuple.new(*elements) }
        end

        def maximums=(array=[])
          @max = []
          array.each { |elements| @max << Tuple.new(*elements) }
        end

        def minimums=(array=[])
          @min = []
          array.each { |elements| @min << Tuple.new(*elements) }
        end

        # @private
        class Tuple
          attr_accessor :spread,
                        :time,
                        :timestamp

          def initialize(timestamp, spread)
            @timestamp = timestamp
            @spread = spread
          end

          def time
            Time.at(timestamp).utc if timestamp
          end

          def to_s
            spread
          end
        end
      end
    end
  end
end
