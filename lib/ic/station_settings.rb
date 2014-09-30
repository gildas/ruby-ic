require 'json'
require 'ic/helpers'
require 'ic/exceptions'
require 'ic/logger'
require 'ic/media_type'

module Ic
  # This interface describes the various StationSettings objects that can be used to connect to CIC Server's stations
  module StationSettings
    # @return [String] the station identifier
    attr_reader :id

    # @return [Session] the current session
    attr_reader :session
    attr_writer :session

    # @return [String] The location path in the URL
    attr_reader :location
    attr_writer :location

    # @return [Array<Fixnum>] The supported media types
    attr_reader :media_types

    def initialize(**options)
      raise MissingArgumentError, 'id' unless (@id = options[:id])
      @media_types = MediaType.from_hash(**options)
      @ready       = options.include?(:ready) ? options[:ready] : true
      @session     = options[:session]
      @location    = '/icws/connection/station'
    end

    def urn_type
      self.class.urn_type
    end

    def ready?
      @ready
    end

    def to_hash
      {
          __type:               urn_type,
          readyForInteractions: ready?,
          supportedMediaTypes:  media_types,
      }
    end

    def to_s
      id
    end

    def to_json
      to_hash.to_json
    end

    def self.from_json(json)
      if json['__type']
      elsif json['stationSetting']
      end
    end
  end
end
