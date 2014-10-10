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
    class AuthorizationError < HTTPError ; end

    # This Exception is raised when the server forbid a request from the client
    class RequestDeniedError < AuthorizationError ; end

    # This Exception is raised when the {Client} did not provide a token in its request
    class AuthTokenExpectedError < ArgumentError ; end

    # This Exception is raised when the {Client} received too many redirection requests
    class TooManyRedirectionsError < HTTPError ; end
  end
end
