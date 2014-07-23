# Adding missing HTTP statuses
# Extracted from lib/ruby/2.1.0/net/http/responses.rb 
module HTTP
  module Status
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


    NOT_IMPLEMENTED                 = 501
    BAD_GATEWAY                     = 502
    SERVICE_UNAVAILABLE             = 503
    GATEWAY_TIMEOUT                 = 504
    VERSION_NOT_SUPPORTED           = 505
    INSUFFICIENT_STORAGE            = 507
    NETWORK_AUTHENTICATION_REQUIRED = 511
  end
end
