module Ic
  # This exception is raised when a method is expecting a parameter, but it was missing
  class MissingArgumentError < ArgumentError ; end

  # This exception is raised when a method is expecting a parameter, but it is invalid
  class InvalidArgumentError < ArgumentError ; end

  # This Exception is raised when the the {Session} is missing
  class MissingSessionError < ArgumentError ; end

  # This Exception is raised when an invalid {Session} is used
  class InvalidSessionError < ArgumentError ; end

  # This Exception is raised when the {Session} is expired
  class ExpiredSessionError < ArgumentError ; end

  # This exception is raised when an object is instanciated from JSON but has the wrong __type
  class InvalidTypeError < ArgumentError ; end

  # This exception is raised when connecting to a station that does not exist
  class StationNotFoundError < IndexError ; end
end
