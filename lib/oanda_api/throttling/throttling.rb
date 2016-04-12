module OandaAPI
  #
  # Everything related to throttling the rate of new connections.
  module Throttling

    # Makes all methods in this module singleton methods.
    extend self

    # Used to synchronize throttling metrics.
    @throttle_mutex = Mutex.new

    def included(base)
      base.send(:extend, ClassMethods)
    end

    # Time that the last connection was created.
    # @return [Time]
    def last_new_connection_at
      @throttle_mutex.synchronize { @last_new_connection_at }
    end

    # Set the time the last new connection was created
    # @param value [Time]
    # @return [Time]
    def last_new_connection_at=(value)
      @throttle_mutex.synchronize { @last_new_connection_at = value }
    end

    # Original (unmonkey-patched) '.new' method of the including class
    # @param klass [Class] the class that has included this module
    # @return [UnboundMethod]
    def original_new_method(klass)
      @original_new_method ||= klass.method(:new).unbind
    end

    # Alias to `Throttling.original_new_method`
    def save_original_new_method(klass)
      original_new_method klass
    end

    # Restores the original '.new' method of the including class
    # @param klass [Class] the class that has included this module
    # @return [void]
    def restore_original_new_method(klass)
      klass.define_singleton_method :new do |*args, &block|
        Throttling.original_new_method(klass).bind(klass).call *args, &block
      end
    end

    # Throttles the connection rate by sleeping for a duration
    #  if the interval bewteen consecutive connections is less
    #  than the allowed minimum. Only throttles when the API
    #  is configured to use_request_throttling.
    # @return [void]
    def throttle_connection_rate
      now = Time.now
      delta = now - (last_new_connection_at || now)
      _throttle(delta, now) if delta < OandaAPI.configuration.min_new_connection_interval &&
                                       OandaAPI.configuration.use_request_throttling?
      self.last_new_connection_at = Time.now
    end

    # Methods in this module are mixed into the including class as singletons.
    module ClassMethods
      #
      # Enables or Disables connection rate limits
      # @param use_throttling [Boolean] if `false` connection rates
      #   are NOT limited
      # @return [void]
      def limit_connection_rate(use_throttling=true)
        klass = self
        Throttling.save_original_new_method klass

        unless use_throttling
          Throttling.restore_original_new_method klass
          return
        end

        connection_rate_limiter = Module.new do
          klass.define_singleton_method :new do |*args, &block|
            Throttling.throttle_connection_rate
            #
            # `super` works here because we use prepend to mix this module
            # into the including class.
            super *args, &block
          end
        end
        prepend connection_rate_limiter
      end
    end

    private
    # @private
    def _throttle(delta, time)
      sleep OandaAPI.configuration.min_new_connection_interval - delta
    end
  end
end

# Mix into Net::HTTP to add rate limiting behavior
Net::HTTP.send :include, OandaAPI::Throttling
