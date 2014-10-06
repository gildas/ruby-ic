require 'json'
require 'ic/logger'
require 'ic/station_settings'

module Ic
  class WorkstationSettings
    include Traceable
    include StationSettings

    def self.urn_type
      'urn:inin.com:connection:workstationSettings'
    end

    def self.station_setting
      1
    end

    def initialize(**options)
      super(**options)
      self.create_logger(**options, default: @session)
      trace.debug('Workstation') { "Workstation: id=#{@id}, ready? #{ready_for_interactions?}" }
    end

    def to_hash
      super.to_hash.merge(workstation: id)
    end
  end
end
