class Hash
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