require 'json'
require 'ic/message'

module Ic
  # This class implements Messages received from CIC that contains data about User Statuses.
  # @example prints the user's status on stdout as it changes:
  #   observer = session.subscribe(message_class: Ic::UserStatusMessage, user: session.user) do |statuses|
  #     statuses.each do |status|
  #       next unless status.user_id == session.user.id
  #       puts "Your status is: #{status}, id=#{status.id}, message=#{status.message}, last change=#{status.changed_at}"
  #     end
  #   end
  class UserStatusMessage
    include Message

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
    def initialize(userStatusList: [], **options)
      super(**options)
      @statuses = userStatusList.collect {|item| Status.new(item)}
    end

    # Creates an {UserStatusMessage} object from JSON data.
    # This class method is called by {Message#from_json}
    # @param json [Hash] The JSON representation
    # @return [Message] The created {Message}
    # @raise [MissingArgumentError] when the JSON data is missing some mandatory keys (__type)
    # @raise [IncalidTypeError]     when The JSON data is of a different type than this class
    def self.from_json(json)
      raise MissingArgumentError, '__type'      unless json[:__type]
      raise InvalidTypeError,     json[:__type] unless json[:__type] == self.urn_type
      self.new(json)
    end


    # Tells the session to subscribe to receive UserStatusMessage notifications.
    # @param session [Session]   The session to subscribe with
    # @param user  [User]        The {User} whom we want the status
    # @param users [Array<User>] The list of {User}s whom we want the status
    # @return [Hash]             a Hash of the response from CIC
    # @raise [MissingArgumentError] when the {Session} is missing or there are no users
    def self.subscribe(session: nil, **options)
      raise MissingArgumentError, 'session' if session.nil?
      raise MissingArgumentError, 'users'   unless options.include?(:user) || options.include?(:users)
      data = { userIds: [] }
      if options[:users]
        data[:userIds] = options[:users].collect { |user| user.respond_to?(:id) ? user.id : :user }
      end
      if options[:user]
        data[:userIds] << (options[:user].respond_to?(:id) ? options[:user].id : options[:user])
      end
      session.http_put path: "/icws/#{session.id}/messaging/subscriptions/status/user-statuses", data: data
    end

    # Tells the session to unsubscribe from receiving UserStatusMessage notifications.
    # @param session [Session]   The session to unsubscribe from
    # @param user  [User]        The {User} whom we want to stop receiving the status
    # @param users [Array<User>] The list of {User}s whom we want to stop receiving the status
    # @return [Hash]             a Hash of the response from CIC
    # @raise [MissingArgumentError] when the {Session} is invalid
    def self.unsubscribe(session: nil)
      raise MissingArgumentError, 'session' if session.nil?
      session.http_delete path: "/icws/#{session.id}/messaging/subscriptions/status/user-statuses"
      #TODO: shouldn't we use a put with a data with current user_ids minus the one we want to stop observe?
    end

    # Called by the framework when {UserStatusMessage} are received.
    # @param message [Message]   The received {Message}
    # @param block   [Block]     The {Block} to yield with the Message status
    # @raise [MissingArgumentError] when the {Message} is invalid
    # @raise [InvalidArgumentError] when the {Message} is of the wrong urn_type
    def self.update(message: nil, &block)
      #TODO: Not sure where but we should support "delta?"
      raise MissingArgumentError, 'message' if message.nil?
      raise InvalidArgumentError, 'message' unless message.urn_type == urn_type
      block.call(message.statuses, message.delta?) if block
    end

    # Gives a String representation of this object
    # @return [String] the String representation of this object
    def to_s
      "#{@statuses.size} Status Message#{@statuses.size > 1 ? 's' : ''}"
    end
  end
end
