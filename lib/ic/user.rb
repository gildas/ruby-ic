require 'json'
require 'time'
require 'ic/helpers'
require 'ic/exceptions'
require 'ic/logger'
require 'ic/rights_filter'
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

    # Finds an existing User on the CIC Server
    #
    # @param session                        [Session]       The Session used by this object.
    # @param id                             [String]        The User Identifier
    # @param select                         [Array<String>] fields to retrieve
    # @param rights_filter                  [RightsFilter]  The RightsFilter to access CIC
    # @param actual_values                  [Boolean]       True to fetch actual values for inheritable data types in addition to the other requested data
    # @param inherited_values               [Boolean]       True to fetch inherited values
    # @param single_property_inherited_from [Boolean]       When set to true, this flag indicates that the inherited from values for a single, inheritable property should be returned in addition to the other requested data. If more than one property is requested when this flag is set, an error response will be returned
    # @param options                        [Hash]          Extra options
    def self.find(session: nil, id: nil, select: [], rights_filter: RightsFilter::ADMIN, actual_values: false, inherited_values: false, single_property_inherited_from: false, **options)
      raise MissingSessionError        unless session
      raise MissingArgumentError, 'id' unless id

      session.trace.info('User') { "Searching for user: #{id}" }
      data = {}
      case
        when select.respond_to?(:join)    then data[:select] = select.join(',')
        when select.kind_of?(String)      then data[:select] = select
        else raise InvalidArgumentError, 'select'
      end unless select.nil? || select.empty?
      data[:rights_filter] = rights_filter       if rights_filter != RightsFilter::ADMIN
      data[:actual_values] = actual_values       if actual_values
      data[:inherited_values] = inherited_values if inherited_values
      data[:single_property_inherited_from] = single_property_inherited_from if single_property_inherited_from

      results = session.http_get path: "/icws/#{session.id}/configuration/users/#{id}", data: data
      options.merge!(results[:configuration_id])
      self.new(session: session, **options)
    end

    # Creates a new User on the CIC Server
    #
    # @param session      [Session] The Session used by this object.
    # @param id           [String]  The User Identifier
    # @param display_name [String]  The USer Display name
    # @param options      [Hash]    Extra options
    def self.create(session: nil, id: nil, display_name: nil, **options)
      raise MissingSessionError        unless session
      raise MissingArgumentError, 'id' unless id
      configuration_id = { id: id }
      configuration_id[:display_name] = display_name unless display_name.nil?
      data = { configuration_id: configuration_id }.merge(options)
      results = session.http_post path: "/icws/#{session.id}/configuration/users", data: data
      trace.debug('user') { "Results: #{results}" }
    end

    # Initializes a new User instance
    #
    # This does not create new users in CIC! Use {User.create} for that
    #
    # All options that do not belong to {Logger} or {HTTP::Client} will become accessors.
    #
    # @param session      [Session] The Session used by this object.
    # @param id           [String]  The User Identifier
    # @param display_name [String]  The USer Display name
    # @param options      [Hash]    Extra options
    # @see Ic::HTTP::Client for HTTP specific options
    # @see Ic::Logger       for Logger specific options
    def initialize(session: nil, id: nil, display_name: nil, **options)
      self.create_logger(**options, default: session)
      @session  = session
      if options[:configuration_id] # We got result from User.find or User.create
        @id       = options[:configuration_id][:id]
        @display  = options[:configuration_id][:display_name]
        @location = options[:configuration_id][:uri]
      else
# TODO: Where can options[:user_id] come from? Need to check with other parts of the code
        @id       = id || options[:user_id]
        @display  = display_name || options[:user_display_name] || @id
        @location = options[:uri]
      end
      options.each_pair do |key, value|
        next if [:logger, :log_to, :log_mode, :log_level, :log_progname, :shift_age, :shift_size, :log_formatter, :default, :content_type, :configuration_id].include? key
        trace.debug('user') { "Adding new attribute #{key} with value: #{value} (#{value.class})" }
        case value
          when TrueClass, FalseClass then key   = (key.to_s + '?').to_sym
          when /\d{6}T\d{6}Z/        then value = Time.parse(value)
        end
        #case key
        #  when :status_text then key, value = :status, Status.new(id: value)
        #end
        #trace.debug('user') { "           attribute #{key} with value: #{value} (#{value.class})" }
        self.class.class_eval do
          define_method(key) do
            value
          end
          if key =~ /(.*)_date/i then
            key = key.to_s.sub(/(.*)_date/, '\1_at').to_sym
            define_method(key.to_s.sub(/(.*)_date/, '\1_at').to_sym) do
              value
            end
          end
        end
      end
      raise MissingArgumentError, 'id' unless @id
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
