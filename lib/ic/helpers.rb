class Hash
  def keys2sym
    keys2sym = lambda do |h|
      Hash === h ? Hash[ h.map {|k, v| [k.respond_to?(:to_sym) ? k.to_sym : k, keys2sym[v]] } ] : h
    end
    keys2sym[self]
  end
end