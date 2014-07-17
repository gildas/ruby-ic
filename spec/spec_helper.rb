require 'json'
require 'ic'

def load_config(filename)
  config = {}
  File.open(filename) do |file|
    config = JSON.parse(file.read)
  end
  keys2sym = lambda do |h|
               Hash === h ? Hash[ h.map {|k, v| [k.respond_to?(:to_sym) ? k.to_sym : k, keys2sym[v]] } ] : h
             end
  keys2sym[config]
end
