require 'json'
require 'ic/message'

module Ic
  class AsyncOperationCompletedMessage
    include Message

    attr_reader :request_id

    def self.urn_type
      'urn:inin.com:messaging:asyncOperationCompletedMessage'
    end

    def initialize(options = {})
      super(options)
      raise MissingArgumentError, 'requestId' unless options[:requestId]
      @request_id = options[:requestId]
    end

    def self.from_json(options = {})
      # Safeguards...
      raise MissingArgumentError, '__type'         unless options[:__type]
      raise InvalidTypeError,     options[:__type] unless options[:__type] == self.urn_type
      self.new(options)
    end
  end
end