require 'json'

module Ic
  # This interface describes the various Message objects that can be received from a CIC Server via the subscription mechanism.
  module Message
    # Initializes a new {Message}.
    # @param isDelta [Boolean] (false) true if this message contains only changed data from a previous {Message}
    # @param [Hash]            options contains other options we can ignore
    def initialize(isDelta: false, **options)
      @is_delta = isDelta
    end

    # Appends member classes of this mixin to an internal list.
    # This list will be used by {Message#from_json} to build the actual message.
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

    # Tells if this message contains only changed data from a previous message.
    # @return [Boolean] True if contains changed data
    def delta? ;  @is_delta end

    # Creates a Hash from the current object.
    # Mainly used to produced JSON data.
    # @return [Hash] a Hash representing the current object
    def to_hash
      {
        __type: urn_type,
      }
    end

    # Creates a JSON representation of the current object.
    # @return [String] a JSON String representing the current object
    def to_json
      to_hash.to_json
    end

    # Creates a specialized {Message} object from JSON data.
    # Member classes must respond to {#from_json}.
    # @param json [Hash] The JSON representation
    # @return [Message] The created {Message}
    # @raise [MissingArgumentError] when the JSON data is missing some mandatory keys (__type)
    # @raise [NotImplementedError]  when no member class implements {#from_json} or has the same urn_type as the JSON data.
    def self.from_json(json)
      raise MissingArgumentError, '__type' unless (type = json[:__type])
      @classes.each do |klass|
        next unless klass.respond_to? :urn_type
        if type == klass.urn_type
          raise NotImplementedError, :from_json unless klass.respond_to? :from_json
          return klass.from_json(json)
        end
      end
      raise NotImplementedError, json[:__type]
    end
  end
end
