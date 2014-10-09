require 'json'
require 'ic/helpers'
require 'ic/exceptions'
require 'ic/logger'

module Ic
  # This class represents a Licence for a CIC object
  # It tells what the server can and cannot do.
  class License
    include Traceable

    # @return [String] The license name
    attr_reader :name

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
    # @param license_name   [String]  The name of the License
    # @param license_status [String]  The current status of the license
    # @param is_available   [Boolean] True if the license is available (for acquisition)
    # @raise [MissingArgumentError] if id and licenseName are nil
    #                               if status and licenseStatus are nil
    def initialize(session: session, license_name: nil, license_status: nil, is_available: false, **options)
      self.create_logger(**options, default: @session)
      raise MissingArgumentError, 'license_name'   unless (@name   = license_name)
      raise MissingArgumentError, 'license_status' unless (@status = license_status)
      @available     = is_available
      @error_details = options[:error_details] || 'none'
      # TODO: Add processing for :errorDetails (which has the value of " none" upon success)
    end

    # @return [Boolean] Tells if a {License}  is available or not.
    def available? ; @available end

    # Creates a Hash from the current object.
    #
    # Mainly used to produced JSON data.
    #
    # @return [Hash] a Hash representing the current object
    def to_hash
      {
        license_name:   @name,
        license_status: @status,
        is_available:   @available
      }
    end
  end
end
