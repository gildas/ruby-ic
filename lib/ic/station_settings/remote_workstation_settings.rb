require 'json'
require 'ic/logger'
require 'ic/station_settings'

module Ic
  # This class is used when connecting to a CIC server with a remote station as the station.
  class RemoteWorkstationSettings
    include Traceable
    include StationSettings

    # @return [String] The remote number of this station
    attr_reader :remote_number

    # The URN type that identifies this class in CIC.
    # @return [String] The URN type of the class
    def self.urn_type
      'urn:inin.com:connection:remoteWorkstationSettings'
    end

    # The Station Setting Type Identifier found in JSON when querying the logged in station.
    # @return [FixNum] The Station Setting Type Identifier
    def self.station_setting
      2
    end

    # Initializes a RemoteWorkstationSettings
    #
    # See {StationSettings#initialize} for common arguments
    # @param remote_number [String] The Remote Number for this station
    # @param options       [Hash]   extra options
    # @raise [MissingArgumentError] When id is null.
    def initialize(remote_number: nil, **options)
      super(**options)
      self.create_logger(**options, default: @session)
      @remote_number = remote_number || options[:remoteNumber]
    end

    # Creates a Hash from the current object.
    # Mainly used to produced JSON data.
    # @return [Hash] a Hash representing the current object
    def to_hash
      super.to_hash.merge(workstation: id, remoteNumber: remote_number)
    end
  end
end
