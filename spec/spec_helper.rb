require 'json'
require 'ic'

def load_config(filename)
  File.open(filename) { |file| JSON.parse(file.read).keys2sym }
end
