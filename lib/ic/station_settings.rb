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

    # @return [Array<Fixnum>] The supported media types, see {MediaType}
    attr_reader :media_types

    # initializes a StationSettings
    #
    # If ready_for_interactions is set to false, when the application is ready to receive
    # interactions, send the same information with ready_for_interactions set to true.
    #
    # @param id                     [String]                 The Station identifier
    # @param media_types            [Array, String, Fixnum]  ([]) contains media type(s), see {MediaType}
    # @param ready_for_interactions [Boolean]                True if ready to receive interactions
    def initialize(id: nil, media_types: [], ready_for_interactions: true, **options)
      raise MissingArgumentError, 'id' unless (@id = id)
      @media_types            = MediaType.from_hash(media_types: media_types, **options)
      @ready_for_interactions = ready_for_interactions
      @session                = options[:session]
      @location               = '/icws/connection/station'
    end

    # Appends member classes of this mixin to an internal list.
    # This list will be used by {Ic::StationSettings.from_json} to build the actual object
    # @param base [Class] The class object to add
    def self.included(base)
      @classes ||= []
      @classes << base
    end

    # The URN type that identifies the member class in CIC.
    # Member classes must respond to {#urn_type}.
    # @return [String] The URN type of the class
    def urn_type
      self.class.urn_type
    end

    # @return [Boolean] True if the application is ready to receive interactions
    def ready_for_interactions?
      @ready_for_interactions
    end

    # Creates a Hash from the current object.
    # Mainly used to produced JSON data.
    # @return [Hash] a Hash representing the current object
    def to_hash
      {
          __type:               urn_type,
          readyForInteractions: ready_for_interactions?,
          supportedMediaTypes:  media_types,
      }
    end

    # Creates a string representation of the current object
    # @return [String] a String representing the current object
    def to_s
      id
    end

    # Creates a JSON representation of the current object.
    # @return [String] a JSON String representing the current object
    def to_json
      to_hash.to_json
    end

    # Creates a specialized {Ic::StationSettings} object from JSON data.
    # Member classes must implement the same class method.
    # @param  [Hash] json             The JSON representation
    # @param  [Hash] options          Additional options
    # @option options [Logger] log_to To trace to an existing {Logger}
    # @return [StationSettings] The created {StationSettings}
    # @raise [MissingArgumentError] when the JSON data is missing some mandatory keys (__type)
    # @raise [NotImplementedError]  when no member class implements {Message.from_json} or has the same urn_type as the JSON data.
    def self.from_json(json, **options)
      logger = options[:log_to] || Ic::Logger.create
      raise MissingArgumentError, '__type' unless (type = json[:__type])
      logger.debug('message') { "Searching type: #{type}" }
      @classes.each do |klass|
        next unless klass.respond_to? :urn_type
        logger.debug('message') { "Message type: #{klass.urn_type}" }
        if type == klass.urn_type
          raise NotImplementedError, :from_json unless klass.respond_to? :from_json
          logger.debug('message') { "   Matched!!!" }
          return klass.from_json(json, **options)
        end
      end
      raise NotImplementedError, json[:__type]
    end
  end
end
