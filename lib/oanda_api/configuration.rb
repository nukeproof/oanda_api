module OandaAPI
  DATETIME_FORMATS = [:rfc3339, :unix]

  # Configures client API settings.
  class Configuration
    DATETIME_FORMAT         = :rfc3339
    MAX_REQUESTS_PER_SECOND = 15
    OPEN_TIMEOUT            = 10
    READ_TIMEOUT            = 10
    REST_API_VERSION        = "v1"
    USE_COMPRESSION         = false
    USE_REQUEST_THROTTLING  = false

    # The format in which dates will be returned by the API (`:rfc3339` or `:unix`).
    # See the Oanda Development Guide for more details about {http://developer.oanda.com/rest-live/development-guide/#date_Time_Format DateTime formats}.
    # @return [Symbol]
    def datetime_format
      @datetime_format ||= DATETIME_FORMAT
    end

    # See {#datetime_format}.
    # @param [Symbol] value
    # @return [void]
    def datetime_format=(value)
      fail ArgumentError, "Invalid datetime format" unless OandaAPI::DATETIME_FORMATS.include? value
      @datetime_format = value
    end

    # The maximum number of requests per second allowed to be made through the
    # API. Only enforced if {#use_request_throttling?} is `true`.
    #
    # @return [Numeric]
    def max_requests_per_second
      @max_requests_per_second ||= MAX_REQUESTS_PER_SECOND
    end

    # See {#max_requests_per_second}.
    # @param [Numeric] value
    # @return [void]
    def max_requests_per_second=(value)
      fail ArgumentError, "must be a number > 0" unless value.is_a?(Numeric) && value > 0
      @min_request_interval = nil
      @max_requests_per_second = value
    end

    # The minimum amount of time in seconds that must elapse between consecutive requests to the API.
    # Determined by {#max_requests_per_second}. Only enforced if {#use_request_throttling?} is `true`.
    # @return [Float]
    def min_request_interval
      @min_request_interval ||= (1.0 / max_requests_per_second)
    end

    # The number of seconds the client waits for a new HTTP connection to be established before
    # raising a timeout exception.
    # @return [Numeric]
    def open_timeout
      @open_timeout ||= OPEN_TIMEOUT
    end

    # See {#open_timeout}.
    # @param [Numeric] value
    # @return [void]
    def open_timeout=(value)
      fail ArgumentError, "must be an integer or float" unless value && (value.is_a?(Integer) || value.is_a?(Float))
      @open_timeout = value
    end

    # The number of seconds the client waits for a response from the API before
    # raising a timeout exception.
    # @return [Numeric]
    def read_timeout
      @read_timeout ||= READ_TIMEOUT
    end

    # See {#read_timeout}.
    # @param [Numeric] value
    # @return [void]
    def read_timeout=(value)
      fail ArgumentError, "must be an integer or float" unless value && (value.is_a?(Integer) || value.is_a?(Float))
      @read_timeout = value
    end

    # The Oanda REST API version used by the client.
    # @return [String]
    def rest_api_version
      @rest_api_version ||= REST_API_VERSION
    end

    # See {#rest_api_version}.
    # @param [String] value
    # @return [void]
    def rest_api_version=(value)
      @rest_api_version = value
    end

    # Specifies whether the API uses compressed responses. See the Oanda Development Guide
    # for more information about {http://developer.oanda.com/rest-live/best-practices/#compression compression}.
    #
    # @return [Boolean]
    def use_compression
      @use_compression = USE_COMPRESSION if @use_compression.nil?
      @use_compression
    end

    alias_method :use_compression?, :use_compression

    # See {#use_compression}.
    # @param [Boolean] value
    # @return [void]
    def use_compression=(value)
      @use_compression = !!value
    end

    # Throttles the rate of requests made to the API. See the Oanda Developers
    # Guide for information about
    # {http://developer.oanda.com/rest-live/best-practices/ connection limits}.
    # If enabled, requests will not exceed {#max_requests_per_second}. If the
    # rate of requests received by the client exceeds this limit, the client
    # delays the rate-exceeding request for the minimum amount of time needed
    # to satisfy the rate limit.
    #
    # @return [Boolean]
    def use_request_throttling
      @use_request_throttling = USE_REQUEST_THROTTLING if @use_request_throttling.nil?
      @use_request_throttling
    end

    alias_method :use_request_throttling?, :use_request_throttling

    # See {#use_request_throttling}.
    # @param [Boolean] value
    # @return [void]
    def use_request_throttling=(value)
      @use_request_throttling = !!value
    end

    # @private
    # @return [Hash] headers that are set on every request as a result of
    #   configuration settings.
    def headers
      h = {}
      h["X-Accept-Datetime-Format"] = datetime_format.to_s.upcase
      h["Accept-Encoding"] = "deflate, gzip" if use_compression?
      h
    end
  end

  # Use to configure application-wide settings.
  #
  # @example Example Usage
  #   OandaAPI.configure |config|
  #     config.use_compression = true
  #     config.use_request_throttling = true
  #   end
  #
  # @yield [Configuration]
  # @return [void]
  def self.configure
    yield configuration
  end

  # @private
  # @return [Configuration]
  def self.configuration
    @configuration ||= Configuration.new
  end
end
