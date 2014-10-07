require 'json'
require 'ic/logger'
require 'ic/station_settings'

module Ic
  # This class is used when connecting to a CIC server with a workstation.
  class WorkstationSettings
    include Traceable
    include StationSettings

    # The URN type that identifies this class in CIC.
    # @return [String] The URN type of the class
    def self.urn_type
      'urn:inin.com:connection:workstationSettings'
    end

    # The Station Setting Type Identifier found in JSON when querying the logged in station.
    # @return [FixNum] The Station Setting Type Identifier
    def self.station_setting
      1
    end

    # Initializes a WorkstationSettings
    #
    # @param id                     [String]                 The Station identifier
    # @param media_types            [Array, String, Fixnum]  ([]) contains media type(s), see {MediaType}
    # @param ready_for_interactions [Boolean]                True if ready to receive interactions
    # @param options                [Hash]                   extra options
    # @raise [MissingArgumentError] When id is null.
    def initialize(**options)
      super(**options)
      self.create_logger(**options, default: @session)
      trace.debug('Workstation') { "Workstation: id=#{@id}, ready? #{ready_for_interactions?}" }
    end

    # Creates a Hash from the current object.
    # Mainly used to produced JSON data.
    # @return [Hash] a Hash representing the current object
    def to_hash
      super.to_hash.merge(workstation: id)
    end
  end
end
