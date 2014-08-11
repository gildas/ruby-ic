require 'json'

module Ic
  module Message
    def initialize(options = {})
      @delta = options[:is_delta] || options[:isDelta]
    end

    def self.included(base)
      @classes ||= []
      @classes << base
    end

    def urn_type
      self.class.urn_type
    end

    def delta? ;  @delta end

    def to_hash
      {
        __type: urn_type,
      }
    end

    def to_json
      to_hash.to_json
    end

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