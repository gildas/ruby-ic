# This exception is raised when a method is expecting a parameter, and it was missing
class MissingArgumentError < ArgumentError ; end

class AuthenticationError < RuntimeError ; end

class SessionIDRequiredError < RuntimeError ;  end
