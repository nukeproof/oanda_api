module OandaAPI
  module Resource
    module Labs
      # Signal value object.
      # See the Oanda Developer Guide for information about {http://developer.oanda.com/rest-live/forex-labs/#autochartist Autochartist}.
      # The nested value objects within are all exposed by Signal.
      class Signal < ResourceBase
        attr_accessor :data, :id, :instrument, :meta, :type

        def initialize(attributes = {})
          attribs = attributes.dup
          @data = Signal::Data.new attribs.delete(:data) || {}
          @meta = Signal::Meta.new attribs.delete(:meta) || {}
          super attribs
        end

        class Data < ResourceBase
          attr_accessor :patternendtime, :points, :prediction, :price
          alias_method :pattern_endtime, :patternendtime

          def initialize(attributes = {})
            attribs = attributes.dup
            @points     = Signal::Points.new attribs.delete(:points) || {}
            @prediction = Signal::Prediction.new attribs.delete(:prediction) || {}
            super attribs
          end
        end

        class Points < ResourceBase
          attr_accessor :keytime, :keytimes, :resistance, :support
          alias_method :key_time, :keytime

          def initialize(attributes = {})
            attribs = attributes.dup
            @resistance = Signal::SupportResistance.new attribs.delete(:resistance) || {}
            @support    = Signal::SupportResistance.new attribs.delete(:support) || {}
            self.key_time = attribs.delete(:keytime) || {}
            super attribs
          end

          # Converts a hash of questionable keys like these:
          #   {:"1" => timestamp, :"3" => timestamp, :"2" => timestamp }
          # into a more reasonable simple array of values, sorted by the
          # index that the hash key implies.
          def key_time=(hash)
            @keytime = hash
            @keytimes = []
            hash.each { |k,v| @keytimes[$1.to_i - 1] = v if k.to_s =~ /(\d+)/ }
          end
        end

        class SupportResistance < ResourceBase
          attr_accessor :x0, :x1, :y0, :y1
        end

        class Prediction < ResourceBase
          attr_accessor :pricehigh, :pricelow, :timebars, :timefrom, :timeto
          alias_method :price_high, :pricehigh
          alias_method :price_low,  :pricelow
          alias_method :time_bars,  :timebars
          alias_method :time_from,  :timefrom
          alias_method :time_to,    :timeto
        end

        class Meta < ResourceBase
          attr_accessor :completed, :direction, :historicalstats, :interval, :length, :pattern, :patterntype, :probability, :scores, :trendtype
          alias_method :completed?, :completed
          alias_method :historical_stats, :historicalstats
          alias_method :pattern_type, :patterntype
          alias_method :trend_type, :trendtype

          def initialize(attributes = {})
            attribs = attributes.dup
            @historicalstats = Signal::HistoricalStats.new attribs.delete(:historicalstats) || {}
            @scores = Signal::Scores.new attribs.delete(:scores) || {}
            super attribs
          end

          def completed?
            !!@completed
          end
        end

        class HistoricalStats < ResourceBase
          attr_accessor :hourofday, :pattern, :symbol
          alias_method :hour_of_day, :hourofday

          def initialize(attributes = {})
            attribs = attributes.dup
            @hourofday = Signal::Stats.new attribs.delete(:hourofday) || {}
            @pattern   = Signal::Stats.new attribs.delete(:pattern) || {}
            @symbol    = Signal::Stats.new attribs.delete(:symbol) || {}
            super attribs
          end
        end

        class Stats < ResourceBase
          attr_accessor :correct, :percent, :total
        end

        class Scores < ResourceBase
          attr_accessor :breakout, :clarity, :initialtrend, :quality, :uniformity
          alias_method :initial_trend, :initialtrend
        end
      end
    end
  end
end
