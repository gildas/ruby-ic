require 'json'
require 'ic/logger'
require 'ic/station_settings'

module Ic
  class RemoteNumberSettings
    include Traceable
    include StationSettings

    attr_writer :persistent

    def self.urn_type
      'urn:inin.com:connection:remoteNumberSettings'
    end

    def self.station_setting
      3
    end

    def initialize(options = {})
      super(options)
      initialize_logger(options)
      @persistent = options[:persistent]
    end

    def persistent?
      @persistent
    end

    def to_hash
      super.to_hash.merge(remoteNumber: id, persistentConnection: persistent?)
    end
  end
end