require 'json'
require 'ic/logger'
require 'ic/message'

module Ic
  # This class implements Messages received from CIC that contains data about User Statuses.
  # @example prints the user's status on stdout as it changes:
  #  observer = user.subscribe to: session, about: Ic::UserStatusMessage do |message|
  #    message.statuses.each do |status|
  #      next unless status.user_id == session.user.id
  #      puts "Your status is: #{status}, id=#{status.id}, message=#{status.message}, last change=#{status.changed_at}"
  #    end
  #  end
  class UserStatusMessage
    include Message
    include Traceable

    # List of {Status}
    # @return [Array<Status>]
    attr_reader :statuses

    # The URN type that identifies this class in CIC.
    # @return [String] The URN type of the class
    def self.urn_type
      'urn:inin.com:status:userStatusMessage'
    end

    # Initializes a new {UserStatusMessage}.
    # @param userStatusList [Array<String>] List of Status identifiers
    # @param options        [Hash]          options used by parent classes
    def initialize(userStatusList: [], isDelta: false, **options)
      self.create_logger(**options)
      super(isDelta: isDelta, **options)
      trace.debug('message') { "Contains #{userStatusList.size} statuses" }
      @statuses = userStatusList.collect {|item| Status.new(item.merge(log_to: logger))}
    end

    # Creates an {UserStatusMessage} object from JSON data.
    # This class method is called by {Ic::Message#from_json}
    # @param  [Hash] json             The JSON representation
    # @param  [Hash] options          Additional options
    # @option options [Logger] log_to To trace to an existing {Logger}
    # @return [Message] The created {Message}
    # @raise [MissingArgumentError] when the JSON data is missing some mandatory keys (__type)
    # @raise [IncalidTypeError]     when The JSON data is of a different type than this class
    def self.from_json(json, **options)
      raise MissingArgumentError, '__type'         unless json[:__type]
      raise InvalidTypeError,     json[:__type]    unless json[:__type] == self.urn_type
      raise MissingArgumentError, 'userStatusList' unless json[:userStatusList]
      self.new(userStatusList: json[:userStatusList], isDelta: json[:isDelta], **options)
    end

    # Gives a String representation of this object
    # @return [String] the String representation of this object
    def to_s
      "#{@statuses.size} Status Message#{@statuses.size > 1 ? 's' : ''}: [#{@statuses.join(',')}]"
    end
  end
end
