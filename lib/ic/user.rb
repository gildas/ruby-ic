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
    # @param session      [Session] The Session used by this object.
    # @param id           [String]  The User Identifier
    # @param display_name [String]  The USer Display name
    # @param options      [Hash]    Extra options
    # @see Ic::HTTP::Client for HTTP specific options
    # @see Ic::Logger       for Logger specific options
    def initialize(id: nil, session: nil, display_name: nil, **options)
      @session = session
      @id      = id || options[:user_id]
      @display = display_name || options[:user_display_name] || @id
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

    # String representation of a User
    #
    # @return [String] String representation
    def to_s
      @id
    end
  end
end
