require 'json'
require 'ic/helpers'
require 'ic/exceptions'
require 'ic/logger'

module Ic
  # This class represents a Licence for a CIC object
  # It tells what the server can and cannot do.
  class License
    include Traceable

    # @return [String] The license identifier
    attr_reader :id

    # @return [Status] The license status.
    attr_reader :status

    # All statuses of a {License}
    module Status
      # An Unknown error occurred when retrieving license info
      UNKNOWN_ERROR                = 0
      # No information is available
      NONE                         = 1
      # The license is available
      AVAILABLE                    = 2
      # The license not assigned
      NOT_ASSIGNED                 = 3
      # The license is not available
      UNAVAILABLE                  = 4
      # The license is used by the same user on another station
      USER_ON_ANOTHER_STATION      = 5
      # The license is used by the same user on another client machine
      STATION_IN_USE_OTHER_MACHINE = 6
      # The license is used by another user
      STATION_IN_USE_OTHER_USER    = 7
      # The license is used by another application
      OTHER_APPLICATION            = 8
    end

    # Initializes a License
    # @param id [String] The Identifier of the License
    # @param licenseName [String] The Identifier of the License (when returned from CIC)
    # @param status [String] The current status of the license
    # @param licenseStatus [String] The current status of the license (when returned from CIC)
    # @raise [MissingArgumentError] if id and licenseName are nil
    #                               if status and licenseStatus are nil
    def initialize(session: session, id: nil, licenseName: nil, status: nil, licenseStatus: nil, **options)
      self.create_logger(**options, default: @session)
      raise MissingArgumentError, 'id'     unless (@id     = id || licenseName)
      raise MissingArgumentError, 'status' unless (@status = status || licenseStatus)
      if options.include?(:available)
        @available = options[:available]
      elsif options.include?(:isAvailable)
        @available = options[:isAvailable]
      else
        @available = false
      end
      # TODO: Add processing for :errorDetails (which has the value of " none" upon success)
    end

    # @return [Boolean] Tells if a {License}  is available or not.
    def available? ; @available end

  end
end
