require 'json'
require 'ic/logger'
require 'ic/message'

module Ic
  # This class implements Messages received from CIC that tell an asynchronous operation is completed.
  class AsyncOperationCompletedMessage
    include Message
    include Traceable

    # The request identifier
    # @return [Fixnum]
    attr_reader :request_id

    # The URN type that identifies this class in CIC.
    # @return [String] The URN type of the class
    def self.urn_type
      'urn:inin.com:messaging:asyncOperationCompletedMessage'
    end

    # Initializes a new {AsyncOperationCompletedMessage}.
    # @param requestId [Fixnum] The Request Identifier
    # @param options   [Hash]   options used by parent classes
    # @raise [MissingArgumentError] when the requestId is missing
    def initialize(requestId: nil, isDelta: false, **options)
      raise MissingArgumentError, 'requestId' if requestId.nil?
      self.create_logger(**options)
      super(isDelta: isDelta, **options)
      @request_id = requestId
    end

    # Creates an {AsyncOperationCompletedMessage} object from JSON data.
    # This class method is called by {Message#from_json}
    # @param  [Hash] json             The JSON representation
    # @param  [Hash] options          Additional options
    # @option options [Logger] log_to To trace to an existing {Logger}
    # @return [Message] The created {Message}
    # @raise [MissingArgumentError] when the JSON data is missing some mandatory keys (__type)
    # @raise [IncalidTypeError]     when The JSON data is of a different type than this class
    def self.from_json(json, **options)
      raise MissingArgumentError, '__type'      unless json[:__type]
      raise InvalidTypeError,     json[:__type] unless json[:__type] == self.urn_type
      raise MissingArgumentError, 'requestId'   unless json[:requestId]
      self.new(requestId: json[:requestId], isDelta: json[:isDelta], **options)
    end

    # Gives a String representation of this object
    # @return [String] the String representation of this object
    def to_s
      "Async Operation Completed Message with request: #{@request_id}"
    end
  end
end
