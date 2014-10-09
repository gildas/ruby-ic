# Additional methods for the Hash class.
#
# @see {::Hash} for general documentation about Hash in Ruby.
class Hash
  # This method takes a Hash with string keys and gives a Hash with symbol keys.
  #
  # @example
  #   foo = { "myKey": "value", "myKeys": [ "value", "myInnerKey": "value" ] }
  #   => { my_key: "value", my_keys: [ "value", my_inner_key: "value" ] }
  #
  # @return [Hash] The resulting Hash
  def keys2sym
    keys2sym = lambda do |h|
      case h
        when Hash  then Hash[ h.map {|k, v| [k.respond_to?(:to_sym) ? k.to_sym : k, keys2sym[v]] } ]
        when Array then h.map {|item| keys2sym[item]}
        else h
      end
    end
    keys2sym[self]
  end
end

# Additional methods for the Array class.
#
# @see {::Array} for general documentation about Array in Ruby.
class Array
  # This method takes an Array with pairs having string keys and gives a Array where the pairs use symbol keys.
  #
  # @example
  #   foo = [ "value", "myKey": "value" ]
  #   => [ "value", my_key: "value" ]
  #
  # @return [Array] The resulting Array
  def keys2sym
    self.collect do |item|
      case item
        when Hash, Aray then item.keys2sym
        else item
    end
    end
  end
end
