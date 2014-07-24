# Adding missing HTTP statuses
# Extracted from lib/ruby/2.1.0/net/http/responses.rb
module Ic
  module HTTP
    module Status
      OK                              = 200
      CREATED                         = 201
      ACCEPTED                        = 202
      NON_AUTHORITATIVE_INFORMATION   = 203
      NO_CONTENT                      = 204
      RESET_CONTENT                   = 205
      PARTIAL_CONTENT                 = 206

      MOVED_PERMANENTLY               = 301
      FOUND                           = 302
      SEE_OTHER                       = 303
      TEMPORARY_REDIRECT              = 307
      MOVED_TEMPORARILY               = 307

      BAD_REQUEST                     = 400
      UNAUTHORIZED                    = 401
      FORBIDDEN                       = 403
      NOT_FOUND                       = 404
      METHOD_NOT_ALLOWED              = 405
      NOT_ACCEPTABLE                  = 406
      PROXY_AUTHENTICATION_REQUIRED   = 407
      REQUEST_TIMEOUT                 = 408
      CONFLICT                        = 409
      GONE                            = 410
      LENGTH_REQUIRED                 = 411
      PRECONDITION_FAILED             = 412

      INTERNAL                        = 500
      NOT_IMPLEMENTED                 = 501
      BAD_GATEWAY                     = 502
      SERVICE_UNAVAILABLE             = 503
      GATEWAY_TIMEOUT                 = 504
      VERSION_NOT_SUPPORTED           = 505
      INSUFFICIENT_STORAGE            = 507
      NETWORK_AUTHENTICATION_REQUIRED = 511
    end
  end
end
