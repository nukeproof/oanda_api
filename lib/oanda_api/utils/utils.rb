module OandaAPI
  # A few general purpose useful methods.
  # Intentionally not implemented as monkey patches.
  # Some wheel-reinventing to avoid adding extra dependencies.
  module Utils
    # Puts camelHumps where you expect them.
    # @param [String] s
    # @return [String]
    def self.camelize(s)
      s.to_s.gsub(/(?:_)([a-z\d]*)/i) { "#{$1.capitalize}" }.sub(/^(.)/) { $1.downcase }
    end

    # Naively plops an "s" at the end of a string.
    # If the string is "" or nil, returns "".
    # @param [String] s
    # @return [String]
    def self.pluralize(s)
      return "" if s.to_s == ""
      s.to_s =~ /s$/ ? s.to_s : "#{s}s"
    end

    # Returns a string with its trailing "s" vaporized.
    # @param [String] s
    # @return [String]
    def self.singularize(s)
      s.to_s.chomp("s")
    end

    # Returns a deep copy of a hash with its keys downcased, underscored
    # and symbolized into ruby sweetness.
    # @param [Hash] hash
    # @return [Hash]
    def self.rubyize_keys(hash)
      transform_hash_keys(hash) { |key| underscore(key).to_sym }
    end

    # Returns a deep copy of a hash with its keys camelized,
    # underscored and symbolized.
    # @param [Hash] hash
    # @return [Hash]
    def self.stringify_keys(hash)
      transform_hash_keys(hash) { |key| camelize key }
    end

    # Yields all keys of a hash, and safely applies whatever transform
    # the block provides. Supports nested hashes.
    #
    # @param [Object] value can be a `Hash`, an `Array` or scalar object type.
    #
    # @param [Block] block transforms the yielded key.
    #
    # @yield [Object] key the key to be prettied up.
    #
    # @return [Hash] a deep copy of the hash with it's keys transformed
    #   according to the design of the block.
    def self.transform_hash_keys(value, &block)
      case
      when value.is_a?(Array)
        value.map { |v| transform_hash_keys(v, &block) }
      when value.is_a?(Hash)
        Hash[value.map { |k, v| [yield(k), transform_hash_keys(v, &block)] }]
      else
        value
      end
    end

    # Yields all key/value pairs of a hash, and safely applies whatever
    # transform the block provides to the values.
    # Supports nested hashes and arrays.
    #
    # @param [Object] value can be a `Hash`, an `Array` or scalar object type.
    #
    # @param [Object] key
    #
    # @param [Block] block transforms the yielded value.
    #
    # @return [Hash] a deep copy of the hash with it's values transformed
    #   according to the design of the block.
    def self.transform_hash_values(value, key = nil, &block)
      case
      when value.is_a?(Array)
        value.map { |v| transform_hash_values(v, key, &block) }
      when value.is_a?(Hash)
        Hash[value.map { |k, v| [k, transform_hash_values(v, k, &block)] }]
      else
        yield key, value
      end
    end

    # Converts a string from camelCase to snake_case.
    # @param [String] s
    # @return [String]
    def self.underscore(s)
      s.to_s
       .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
       .gsub(/([a-z\d])([A-Z])/, '\1_\2')
       .tr("-", "_")
       .downcase
    end
  end
end
