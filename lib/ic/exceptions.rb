module Ic
# This exception is raised when a method is expecting a parameter, but it was missing
  class MissingArgumentError < ArgumentError ; end

  class StationNotFoundError < IndexError ; end
end
