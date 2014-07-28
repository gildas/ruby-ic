module Ic
  module HTTP
    class HTTPError < RuntimeError ; end

    class WantRedirection < HTTPError ; end

    class BadRequestError < HTTPError ; end

    class NotFoundError < HTTPError ; end

    class AuthenticationError < HTTPError ; end

    class UnauthorizedError < HTTPError ; end

    class TooManyRedirectionsError < HTTPError ; end

  end
end
