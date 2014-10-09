# Additional methods for the String class.
#
# @see {::String} for general documentation about String in Ruby.
class String
  # This method will "camelize" a String
  # 
  # @example
  #   "my_value".to_camel
  #   => "MyValue"
  #
  # @example
  #   "my_value".to_camel(:lower)
  #   => "myValue"
  #
  # @param lower [Boolean] If true, the first character will be lowercase
  # @return [String] The camelized Sstring
  def to_camel(lower: false)
    return self unless self =~ /_/
    if lower
      self.split('_').inject([]){|result, word| result.push(result.empty? ? word : word.capitalize)}.join
    else
      self.split('_').collect(&:capitalize).join
    end
  end

  # This method will "snakerize" a String
  #
  # @example
  #  "MyTestValue".to_snake
  #  => "my_test_value"
  #
  # @return [String] The snakerized String
  def to_snake
    self.gsub(/::/, '/')
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .tr('-', '_')
        .downcase
  end
end

# Additional methods for the Symbol class.
#
# @see {::Symbol} for general documentation about Symbol in Ruby.
class Symbol
  # This method will "camelize" a Symbol
  # 
  # @example
  #   :my_value.to_camel
  #   => :MyValue
  #
  # @example
  #   :my_value.to_camel(:lower)
  #   => :myValue
  #
  # @param lower [Boolean] If true, the first character will be lowercase
  # @return [Symbol] The camelized Symbol
  def to_camel(lower: false)
    return to_s.to_camel(lower: lower).to_sym
  end

  # This method will "snakerize" a Symbol
  #
  # @example
  #  :MyTestValue.to_snake
  #  => :my_test_value
  #
  # @return [Symbol] The snakerized Symbol
  def to_snake
    return to_s.to_snake.to_sym
  end
end

# Additional methods for the Hash class.
#
# @see {::Hash} for general documentation about Hash in Ruby.
class Hash
  # This method takes a Hash with string keys and gives a Hash with symbol keys.
  #
  # @example
  #   foo = { "myKey": "value", "myKeys": [ "value", "myInnerKey": "value" ] }
  #   foo.keys2sym
  #   => { my_key: "value", my_keys: [ "value", my_inner_key: "value" ] }
  #
  # @return [Hash] The resulting Hash
  def keys2sym
    keys2sym = lambda do |h|
      case h
        when Hash  then Hash[ h.map {|k, v| [k.respond_to?(:to_sym) ? k.to_snake.to_sym : k, keys2sym[v]] }]
        when Array then h.map {|item| keys2sym[item]}
        else h
      end
    end
    keys2sym[self]
  end

  # This methods takes a Ruby Hash with symbol (using snake notation)
  # and gives a JSON Hash with camelized String keys.
  #
  # @example
  #   foo = { my_key: "value", my_keys: [ "value", my_inner_key: "value" ] }
  #   foo.keys2camel
  #   => { "MyKey": "value", "MyKeys": [ "value", "myInnerKey": "value" ] }
  #
  # @example
  #   foo = { __type: 'urn:acme.com:foo', my_key: "value", my_keys: [ "value", my_inner_key: "value" ] }
  #   foo.keys2camel(lower: true, except: [ :__type ])
  #   => { "__type": "urn:acme.com:foo",  "myKey": "value", "myKeys": [ "value", "myInnerKey": "value" ] }
  #
  # @param lower [Boolean] If true, the first character will be lowercase
  # @param except [Array<Symbol>] Contains symbols that should not be camelized just converted to String
  # @return [Hash] The resulting Hash
  def keys2camel(lower: false, except: [])
    keys2camel = lambda do |h|
      case h
      when Hash then Hash[ h.map {|k, v| [except.include?(k) ? k.to_s : k.to_s.to_camel(lower: lower), keys2camel[v]] }]
        when Array then h.map {|item| keys2camel[item]}
        else h
      end
    end
    keys2camel[self]
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
  #   foo.keys2sym
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

  # This methods takes an Array with pairs having symbol for their key (using snake notation)
  # and gives an Array with camelized String keys.
  #
  # @example
  #   foo = [ "value", my_key: "value" ]
  #   foo.keys2sym
  #   => [ "value", "myKey": "value" ]
  #
  # @return [Array] The resulting Array
  def keys2camel
    self.collect do |item|
      case item
        when Hash, Aray then item.keys2camel
        else item
      end
    end
  end
end
