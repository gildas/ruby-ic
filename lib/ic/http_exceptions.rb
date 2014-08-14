module Ic
  module HTTP
    class HTTPError < RuntimeError ; end

    class WantRedirection < HTTPError ; end

    class UnavailableService < HTTPError ; end

    class BadRequestError < HTTPError ; end

    class NotFoundError < HTTPError ; end

    class AuthenticationError < HTTPError ; end

    class UnauthorizedError < HTTPError ; end

    class SessionIdExpectedError < UnauthorizedError ; end

    class AuthTokenExpectedError < UnauthorizedError ; end

    class InvalidSessionIdError < UnauthorizedError ; end

    class TooManyRedirectionsError < HTTPError ; end

  end
end
