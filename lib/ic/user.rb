require 'json'
require 'ic/helpers'
require 'ic/exceptions'
require 'ic/logger'
require 'ic/status'
require 'ic/subscriber'

module Ic
  # This class represents a CIC User
  # 
  # It can be used for User in Session, Queues, etc. as well as to perform administrative tasks
  # such as create a new User, Change their attributes or group membership, etc...
  class User
    include Traceable
    include Subscriber

    # @return [String] The User Identifier
    attr_reader :id

    # #return [String] The User Display name
    attr_reader :display
    attr_writer :display

    # Initializes a new User instance
    #
    # This does not create new users in CIC! Use {User.create} for that
    #
    # @param session [Session] The Session used by this object.
    # @param id      [String]  The User Identifier
    # @param display [String]  The USer Display name
    # @param options [Hash]    Extra options
    # @see Ic::HTTP::Client for HTTP specific options
    # @see Ic::Logger       for Logger specific options
    def initialize(id: nil, session: nil, display_name: nil, **options)
      @session = session
      @id      = id || options[:user_id]
      @display = display_name || options[:user_display_name]
      self.create_logger(**options, default: @session)
      logger.add_context(user: @id)
    end

    # Queries the CIC Server for the User's Status
    #
    # @return [Status] the retrieved Status
    # @raise [MissingSessionError] when the session is missing
    def status
      raise MissingSessionError unless @session
      trace.debug('User') { 'Requesting the current status' }
      info = @session.http_get path: "/icws/#{@session.id}/status/user-statuses/#{@id}"
      trace.info('User') { "Status: #{info}" }
      info[:session] = @session
      Status.new(info.merge(user: self))
    end

    # Sets the User's Status on the CIC Server
    #
    # @param options [Hash] Status parameters
    # @raise [MissingSessionError] when the session is missing
    # @raise [MissingArgumentError] when the status is missing
    def status=(options = {})
      options = { status: options } if options.kind_of?(String) || options.kind_of?(Status)
      raise MissingArgumentError, 'status' unless options[:status]
      raise MissingSessionError unless @session
      data = {}
      if options[:status].respond_to?(:id)
        data[:statusId]      = options[:status].id
        data[:forwardNumber] = status.forward_to if status.forward_to
        data[:notes]         = status.notes      if status.notes && !status.notes.empty?
        if status.until
          data[:until]       = {
              untilDateTime: status.until,
              hasDate:       options[:has_date],
              hasTime:       options[:has_time],
          }
        end
      else
        data[:statusId]    = options[:status]
      end
      data[:forwardNumber] = options[:forward_to] if options.include?(:forward_to)
      data[:notes]         = options[:notes]      if options.include?(:notes)
      trace.debug('User') { "Setting the status to #{data[:statusId]}" }
      info = @session.http_put path: "/icws/#{@session.id}/status/user-statuses/#{@id}", data: data
      trace.info('User') { "Status: #{info}" }
      info[:requestId]
    end

    # Subscribes to a {Message} on the current {Session}
    #
    # @param to      [Message]    the type of {Message}
    # @param options [Hash]       options
    # @param block   [Code]       Code to execute when the Observable notifies this
    # @raise [MissingSessionError] when the session is missing
    def subscribe(to: nil, **options, &block)
      raise MissingArgumentError, 'to' if to.nil?
      trace.info('subscribe') { "Subscribing user #{self} to message #{to} on session #{@session}"}
      #super.subscribe(to: to, about: about, **options, &block)
      @update_about = to
      @update_block = block
      @session.add_observer(self)
      to.subscribe(session: @session, user: self)
    end

    # Unsubscribe from an Observable object
    #
    # @param from [Observable] an Observable object
    # @raise [MissingSessionError] when the session is missing
    def unsubscribe(from: nil)
      trace.info('subscribe') { "Unsubscribing user #{self} from message #{from} on session #{@session}"}
      #super.unsubscribe(from: from)
      @session.delete_observer(self)
      @update_about = @update_block = nil
      from.unsubscribe(session: @session, user: self)
    end

    # Called by the Observable object when it changes
    #
    # @param message [Hash] parameters given by the Observable
    # @raise [MissingArgumentError] when the message is missing
    # @raise [InvalidArgumentError] when the message is invalid
    def update(message)
      trace.debug('subscribe') { "Received message: #{message}" }
      raise MissingArgumentError, 'message' if message.nil?
      raise InvalidArgumentError, 'message' unless message.kind_of? Message
      begin
        @update_block.call(message) if @update_block
      rescue
        trace.error('subscribe') { "While executing code block: #{@update_block}, Exception: #{$!}" }
      end
    end

    # String representation of a User
    #
    # @return [String] String representation
    def to_s
      @id
    end
  end
end
