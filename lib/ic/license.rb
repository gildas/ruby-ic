require 'json'
require 'ic/helpers'
require 'ic/exceptions'
require 'ic/logger'

module Ic
  class License
    include Traceable

    attr_reader :id, :status

    module Status
      UNKNOWN_ERROR                = 0
      NONE                         = 1
      AVAILABLE                    = 2
      NOT_ASSIGNED                 = 3
      UNAVAILABLE                  = 4
      USER_ON_ANOTHER_STATION      = 5
      STATION_IN_USE_OTHER_MACHINE = 6
      STATION_IN_USE_OTHER_USER    = 7
      OTHER_APPLICATION            = 8
    end

    def initialize(**options)
      raise MissingArgumentError, 'session' unless (@session = options[:session])
      self.create_logger(**options, default: @session)
      raise MissingArgumentError, 'id'     unless (@id     = options[:id] || options[:licenseName])
      raise MissingArgumentError, 'status' unless (@status = options[:status] || options[:licenseStatus])
      if options.include?(:available)
        @available = options[:available]
      elsif options.include?(:isAvailable)
        @available = options[:isAvailable]
      else
        @available = false
      end
      # TODO: Add processing for :errorDetails (which has the value of " none" upon success)
    end

    def available? ; @available end

  end
end
