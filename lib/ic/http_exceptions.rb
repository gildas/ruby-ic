module Ic
  module HTTP
    # This is the generic exception for HTTP Errors
    class HTTPError < RuntimeError ; end

    # This Exception is raised when the {Client} receives a request to redirect from the server 
    class WantRedirection < HTTPError ; end

    # This Exception is raised when the server is not able to serve the {Client}
    class UnavailableService < HTTPError ; end

    # This Exception is raised when the {Client} did not formulate its request properly
    class BadRequestError < HTTPError ; end

    # This Exception is raised when the {Client} asked for a resource that does not exist
    class NotFoundError < HTTPError ; end

    # This Exception is raised when the server cannot authenticate the {Client}
    class AuthenticationError < HTTPError ; end

    # This Exception is raised when the {Client} is not authorized on the server
    class UnauthorizedError < HTTPError ; end

    # This Exception is raised when the {Client} used a {Session} that is expired
    class SessionIdExpectedError < UnauthorizedError ; end

    # This Exception is raised when the {Client} did not provide a token in its request
    class AuthTokenExpectedError < UnauthorizedError ; end

    # This Exception is raised when the {Client} received too many redirection requests
    class TooManyRedirectionsError < HTTPError ; end
  end
end
