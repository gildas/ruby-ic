require 'json'
require 'ic/logger'
require 'ic/station_settings'

module Ic
  class RemoteWorkstationSettings
    include Traceable
    include StationSettings

    attr_reader :remote_number

    def self.urn_type
      'urn:inin.com:connection:remoteWorkstationSettings'
    end

    def self.station_setting
      2
    end

    def initialize(options = {})
      super(options)
      initialize_logger(options)
      @remote_number = options[:remote_number] || options[:remoteNumber]
    end

    def to_hash
      super.to_hash.merge(workstation: id, remoteNumber: remote_number)
    end
  end
end
