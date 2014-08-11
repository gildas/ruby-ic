module Ic
# This exception is raised when a method is expecting a parameter, but it was missing
  class MissingArgumentError < ArgumentError ; end

# This exception is raised when a method is expecting a parameter, but it is invalid
  class InvalidArgumentError < ArgumentError ; end

# This exception is raised when an object is instanciated from JSON but has the wrong __type
  class InvalidTypeError < ArgumentError ; end

  class StationNotFoundError < IndexError ; end
end
