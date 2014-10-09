require 'json'
require 'ic/logger'
require 'ic/station_settings'

module Ic
  # This class is used when connecting to a CIC server with a remote number as the station.
  class RemoteNumberSettings
    include Traceable
    include StationSettings

    # Sets the persistent flag
    attr_writer :persistent

    # The URN type that identifies this class in CIC.
    # @return [String] The URN type of the class
    def self.urn_type
      'urn:inin.com:connection:remoteNumberSettings'
    end

    # The Station Setting Type Identifier found in JSON when querying the logged in station.
    # @return [FixNum] The Station Setting Type Identifier
    def self.station_setting
      3
    end

    # Initializes a RemoteNumberSettings
    #
    # When :persistent is true, the CIC server will not hang up the voice link
    # with the remote number.
    #
    # By default, the persistence is set to false.
    # 
    # See {StationSettings#initialize} for common arguments
    # @param persistent [Boolean] true for persistent voice path.
    # @param options    [Hash]    extra options
    # @raise [MissingArgumentError] When id is null.
    def initialize(persistent: false, **options)
      super(**options)
      self.create_logger(**options, default: @session)
      @persistent = persistent
    end

    # @return [Boolean] Tells if the voice link 
    def persistent?
      @persistent
    end

    # Creates a Hash from the current object.
    # Mainly used to produced JSON data.
    # @return [Hash] a Hash representing the current object
    def to_hash
      super.to_hash.merge(remoteNumber: id, persistentConnection: persistent?)
    end
  end
end
