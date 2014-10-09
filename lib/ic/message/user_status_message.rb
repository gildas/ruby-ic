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
    # @param status_ids [Array<String>] List of Status identifiers
    # @param options  [Hash]          options used by parent classes
    def initialize(status_ids: [], **options)
      self.create_logger(**options)
      super(**options)
      trace.debug('message') { "Contains #{status_ids.size} statuses" }
      @statuses = status_ids.collect {|item| Status.new(item.merge(log_to: logger))}
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
      raise MissingArgumentError, 'user_status_list' unless json[:user_status_list]
      self.new(status_ids: json[:user_status_list], is_delta: json[:is_delta], **options)
    end

    # Susbcribe to a {Session} for updates about a user or some users.
    #
    # The data can be given as User or their string identifiers.
    # The data can be a single object or an Enumerable of objects.
    #
    # If data is empty, no subscription is sent to CIC.
    #
    # @example
    #   UserStatusMessage.subscribe(session: session, data: [ 'cicadmin', user1, user2 ])
    #
    # @example with only one user:
    #  UserStatusMessage.subscribe(session: session, data: user1)
    #
    # @param session [Session] The Session
    # @param data    [Array<User,String>] Contains the users (or their identifier)
    # @raise [MissingSessionError] When the session is missing
    def self.subscribe(session: nil, data: nil)
      raise MissingSessionError if session.nil?
      data ||= [] # At least we must have an empty array
      data = [ data ] unless data.kind_of? Enumerable
      return if data.empty?
      session.http_put path: "/icws/#{session.id}/messaging/subscriptions/status/user-statuses", data: { userIds: data.collect {|item| item.respond_to?(:id) ? item.id : item } }
    end

    # Unsubscribe from a {Session} for updates about a user or some users.
    #
    # The data can be given as User or their string identifiers.
    # The data can be a single object or an Enumerable of objects.
    #
    # If data is empty, all currently active subscriptions are canceled from CIC.
    #
    # @example
    #   UserStatusMessage.unsubscribe(session: session, data: [ 'cicadmin', user1, user2 ])
    #
    # @example with only one user:
    #  UserStatusMessage.unsubscribe(session: session, data: user1)
    #
    # @note At the moment, it is not possible to unsubscribe one or a few users only. All subscriptions are canceled.
    #
    # @param session [Session] The Session
    # @param users   [Array<User,String>] Contains the users (or their identifier)
    # @param user    [User,String]        Contains the user (or their identifier)
    # @raise [MissingSessionError] When the session is missing
    def self.unsubscribe(session: nil, data: nil)
      raise MissingSessionError if session.nil?
      data ||= [] # At least we must have an empty array
      data = [ data ] unless data.kind_of? Enumerable
      if data.empty?
        session.http_delete path: "/icws/#{session.id}/messaging/subscriptions/status/user-statuses"
      else
        #TODO: We need to unsubscribe only the given User list!!!
        session.http_delete path: "/icws/#{session.id}/messaging/subscriptions/status/user-statuses"
      end
    end

    # Gives a String representation of this object
    # @return [String] the String representation of this object
    def to_s
      "#{@statuses.size} Status Message#{@statuses.size > 1 ? 's' : ''}: [#{@statuses.join(',')}]"
    end
  end
end
