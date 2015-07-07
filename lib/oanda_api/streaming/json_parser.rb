require_relative 'adapter_error'

module OandaAPI
  module Streaming
    #
    # Used to deserialize a stream of JSON objects. Will load and use a streaming JSON parser
    # if one is installed, otherwise defaults to use the JSON gem.
    #
    # Much of this module's code was borrowed from [multi_json](https://github.com/intridea/multi_json).
    module JsonParser
      extend self

      # Map parser adapters to the gem library they require.
      REQUIREMENT_MAP = {
        gson: "gson",
        yajl: "yajl"
      }

      # Loads (if not already loaded) and returns the current adapter class.
      # @return [.parse] a class implementing a `.parse` method
      def adapter
        return @adapter if defined?(@adapter) && @adapter

        # Load default adapter
        self.use nil
        @adapter
      end

      # Returns a symbol identifying either the currently loaded adapter or
      #  one that can be loaded. Preference is given to an adapter optimized
      #  for parsing streaming json if it is installed.
      #
      # @return [Symbol] a symbol identifying an adapter either currently loaded or that
      #  one that can be loaded.
      def default_adapter
        jruby? ? try_adapter(:gson) : try_adapter(:yajl)
      end

      # Loads the requested adapter.
      # @param [nil, String, Symbol, Module, Class] new_adapter identifies an adapter to load.
      # @return[.parse] a Module or Class that implements a `.parse` method for deserializing a stream of JSON objects.
      def use(new_adapter)
        @adapter = load_adapter(new_adapter)
      end
      alias adapter= use

      # Loads the requested adapter.
      # @param [String, Symbol, nil, false, Class, Module] new_adapter identifies an adapter to load.
      # @return [.parse] a Module or Class that implements a `.parse` method for deserializing a stream of JSON objects.
      # @raise [AdapterError] if the adapter cannot be loaded.
      def load_adapter(new_adapter)
        case new_adapter
        when String, Symbol
          load_adapter_from_string_name new_adapter.to_s
        when NilClass, FalseClass
          load_adapter default_adapter
        when Class, Module
          new_adapter
        else
          fail ::LoadError, new_adapter
        end
      rescue ::LoadError => exception
        raise AdapterError.build(exception)
      end

      private

      # @return [true] if jRuby is the ruby execution engine
      def jruby?
        defined?(RUBY_ENGINE) && (RUBY_ENGINE =~ /jruby/i)
      end

      # Loads the requested adapter.
      # @param [String] name the adapter to load.
      # @return [Class, Module] the loaded adapter
      def load_adapter_from_string_name(name)
        require_relative "adapters/#{name.downcase}"
        klass_name = name.to_s.split('_').map(&:capitalize) * ''
        OandaAPI::Streaming::Adapters.const_get(klass_name)
      end

      # Checks if the requested adapter is loadable.
      #  Returns a symbol identifiying either the requested adapter or
      #  a generic loadable adapter.
      # @param [Symbol] sym identifies an adapter.
      # @return [Symbol] a symbol identifying a loadable adapter.
      def try_adapter(sym)
        begin
          return sym if Kernel.const_get sym.to_s.capitalize
        rescue ::NameError
          nil
        end

        begin
          require REQUIREMENT_MAP.fetch sym
          return sym
        rescue ::LoadError
          warning
          return :generic
        end
      end

      # Writes a warning to stdout about the generic json parser.
      # @return[void]
      def warning
        Kernel.warn <<-END
        +------------------------------------------------------------------+
        + Warning: You're currently using a JSON parser that doesn't       +
        +          handle streams of JSON objects very well. For faster    +
        + and more reliable parsing, it's recommended to install one of    +
        + following gems dependent on the Ruby engine you're using. Once   +
        + installed, OandaAPI::Streaming will detect the upgraded parser   +
        + and use it.                                                      +
        +                                                                  +
        + RUBY_ENGINE  Recommended JSON Parsing Gem                        +
        + ===========  ==================================================  +
        + ruby or rbx  yajl-ruby (http://github.com/brianmario/yajl-ruby)  +
        +              install with: gem install yajl-ruby                 +
        +                                                                  +
        +                                                                  +
        + jruby        gson (https://github.com/avsej/gson.rb)             +
        +              install with: gem install gson                      +
        +------------------------------------------------------------------+
        END
      end
    end
  end
end
