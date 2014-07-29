require 'json'
require 'ic/helpers'
require 'ic/exceptions'
require 'ic/logger'
require 'ic/media_type'

module Ic
  module StationSettings
    attr_reader :id, :session, :location, :media_types
    attr_writer :session, :location

    def initialize(options = {})
      raise MissingArgumentError, 'id' unless (@id = options[:id])
      @media_types = MediaType.from_hash(options)
      @ready       = options.include?(:ready) ? options[:ready] : true
      @session     = options[:session]
      @location    = Ic::Session::BASE_LOCATION + '/station'
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
