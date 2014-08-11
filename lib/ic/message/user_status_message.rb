require 'json'
require 'ic/message'

module Ic
  class UserStatusMessage
    include Message

    attr_reader :statuses

    def self.urn_type
      'urn:inin.com:status:userStatusMessage'
    end

    def initialize(options = {})
      super(options)
      raise MissingArgumentError, 'userStatusList' unless options[:userStatusList]
      @statuses = options[:userStatusList].collect {|item| Status.new(item)}
    end

    def self.from_json(options = {})
      # Safeguards...
      raise MissingArgumentError, '__type'         unless options[:__type]
      raise InvalidTypeError,     options[:__type] unless options[:__type] == self.urn_type
      self.new(options)
    end
  end
end