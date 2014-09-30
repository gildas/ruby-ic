require 'json'
require 'observer'
require 'ic/helpers'
require 'ic/http'
require 'ic/exceptions'
require 'ic/logger'
require 'ic/message'
require 'ic/user'
require 'ic/license'

module Ic
  # This class is used to connect to a CIC Server
  # 
  class Session
    include Observable
    include Traceable
    include HTTP::Requestor

    # Maximum redirections allowed to alternate CIC servers
    MAX_REDIRECTIONS = 5

    # The default Application name with CIC Server
    DEFAULT_APPLICATION = "ICWS Ruby Client"

    # How often the poll thread should check for messages
    DEFAULT_POLL_FREQUENCY = 5

    # @return [String] The session identifier with the CIC Server
    attr_reader :id

    # @return [String] The application name used when connecting to the CIC Server
    attr_reader :application

    # @return [User] The {User} connected to the CIC Server
    attr_reader :user

    # @return [Server] The CIC Server
    attr_reader :server

    # @return [HTTP::Client] The {HTTP::Client} that communicates with the CIC Server
    attr_reader :client

    # Class method that initializes a session and connects it to a CIC Server
    #
    # @param (see #initialize)
    # @return [Session] The connected session
    def self.connect(server: nil, user: nil, password: nil, application: nil, poll_frequency: nil, **options)
      Session.new(server: server, user: user, password: password, application: application, poll_frequency: poll_frequency, **options).connect
    end

    # Initializes a new Session.
    #
    # The new Session is not yet connected! use {#connect} to connect to a CIC Server
    #
    # it is possible to load a configuration stored in JSON, by providing a :from
    # in the options hash. Note the keyword values override the JSON config.
    #
    # @example Create a new Session via the keywords:
    #   session = Ic::Session.new(server: 'localhost', user: 'admin', password: 'S3cr3t')
    #
    # @example loading a configuration stored in JSON:
    #   session = Ic::Session.new(from: 'config/login.json')
    #
    # @example combined with {#connect}:
    #  session = Ic::Session.connect from: 'config/login.json'
    #
    # @example or even:
    #  File.open('config/login.json') do |file|
    #    session = Ic::Session.connect from: file
    #  end
    #
    # @param server         [String] The CIC Server
    # @param user           [String] The CIC user to connect with
    # @param password       [String] The user's password
    # @param application    [String] The name of the application for the CIC Server
    # @param poll_frequency [Fixnum] The message poll frequency
    # @param options        [Hash]   Extra options
    # @option options [String,File,IO] :from (nil) To load a JSON config
    # @raise [MissingArgumentError] when the user and/or the password are empty
    # @raise [InvalidArgumentError] when the :from option is invalid
    # @see Ic::HTTP::Client for HTTP specific options
    # @see Ic::Logger       for Logger specific options
    def initialize(server: nil, user: nil, password: nil, application: nil, poll_frequency: nil, **options)
      if options[:from]
        config = {}
        case options[:from]
          when String             then File.open(options[:from]) { |file| config = JSON.parse(file.read) }
          when File, StringIO, IO then  config = JSON.parse(options[:from].read)
          else raise InvalidArgumentError, 'from'
        end
        options = config.keys2sym.merge(options)
      end
      raise MissingArgumentError, 'user'     unless (user ||= options[:user])
      raise MissingArgumentError, 'password' unless (@password = password || options[:password])
      self.create_logger(**options)
      @application            = application || options[:application] || DEFAULT_APPLICATION
      @server                 = server || options[:server] || 'localhost'
      self.client             = Ic::HTTP::Client.new(server: @server, log_to: logger, **options)
      @id                     = nil
      @location               = '/icws/connection'
      @user                   = User.new(session: self, id: user)
      @message_poll_frequency = poll_frequency || DEFAULT_POLL_FREQUENCY
      @message_thread         = nil
      @message_poll_active    = false
      trace.debug('Session') { "Server: \"#{server}\", options: #{options[:server]} => @server: \"#{@server}\"" }
    end

    # Connects to the CIC Server that was given during {#initialize}
    #
    # If the Session was already connected, it is disconnected before proceeding.
    # The connection process handles also Switchover pairs or alternate
    # servers up to {MAX_REDIRECTIONS}.
    #
    # Upon successful connection, the session starts polling for messages.
    #
    # @return [Session] The connected session
    # @raise [KeyError]                 when the response does not contain proper data
    # @raise [TooManyRedirectionsError] when too many redirections occur
    def connect
      disconnect if connected?
      data = {
        __type:          'urn:inin.com:connection:icAuthConnectionRequestSettings',
        applicationName: @application,
        userID:          @user.id,
        password:        @password,
      }
      alternate_server_index = 0
      server = client.server
      loop do
        trace.info('Session') { "Connecting application \"#{@application}\" to #{server} as #{@user}" }
        begin
          session_info = http_post server: server, path: @location, data: data
          raise KeyError, 'sessionId' unless (@id       = session_info[:sessionId])
          raise KeyError, 'location'  unless (@location = session_info[:location])
          raise KeyError, 'csrfToken' unless session_info[:csrfToken]
          @user.display ||= session_info[:userDisplayName]
          logger.add_context(session: @id)
          trace.info('Session') { "Successfully Connected to Session #{@id}, located at: #{@location}" }
          poll_messages
          return self
        rescue HTTP::WantRedirection => e
          trace.warn('Session') { 'We need to check other servers' }
          servers = JSON.parse(e.message).keys2sym[:alternateHostList]
          trace.info('Session') { "alternate servers: [#{servers.join(', ')}]" }
          server = servers.first
          raise TooManyRedirectionsError if alternate_server_index >= MAX_REDIRECTIONS
          alternate_server_index += 1
        end
      end
    end

    # Disconnects from the current CIC Server
    #
    # If the Session was already disconnected, the method silently returns.
    #
    # Before disconnecting, the Session stops polling for messages.
    #
    # @return [Session] The disconnected session
    def disconnect
      return self unless connected?
      trace.info('messages') { "Stopping Message polling" }
      @message_poll_active = false
      @message_thread.join
      trace.debug('Session') { "Disconnecting from #{client.server}" }
      http_delete path: @location, session: self
      trace.info('Session') { "Successfully disconnected from #{client.server}" }
      logger.remove_context(session: @id)
      @id = nil
      self
    end

    # Tells if the session is currently connected to a CIC Server
    # @return [Boolean] True if the session is connected
    def connected?
      ! @id.nil?
    end

    # Contains the language for the localized messages from the CIC Server
    #
    # The language format is: xx-yy,
    # where xx is the language code and yy is the country code
    #
    # return [String] The current language
    # @see http://www.iso.org/iso/home/standards/language_codes.htm Language codes (ISO 639-1)
    # @see http://www.iso.org/iso/country_codes.htm Country codes (ISO 3166)
    def language
      @client.language
    end

    # Queries the CIC Server for its version
    #
    # @return [String] The collected version information
    def version
      version = http_get path: "#{@location}/version"
      trace.info('Session') { "Server version: #{version}" }
      version
    end

    # Queries the CIC Server for all licensed features
    #
    # @return [Array<String>] A list of feature names
    def features
      features = @client.get path: "#{@location}/features"
      trace.info('Session') { "Server features: #{features}" }
      raise ArgumentError, 'featureInfoList' unless features[:featureInfoList]
      features[:featureInfoList]
    end

    # Queries the CIC Server to know if a feature is licensed ot not
    #
    # @param feature [String] The feature name
    # @return [Boolean] True if the feature is licensed
    def feature?(feature)
      begin
        trace.debug('Session') { "Querying feature \"#{feature}\""}
        feature = http_get path: "#{@location}/features/#{feature}"
        trace.info('Session') { "Supported feature: #{feature}" }
        true
      rescue HTTP::BadRequestError => e
        trace.info('Session') { "Unsupported feature: #{feature}, error: #{e.message}"}
        false
      end
    end

    # Queries the CIC Server for information about a feature
    #
    # @param feature [String] The feature name
    # @return [Hash] The feature information
    # @raise [HTTP::BadRequestError] when the feature is not licensed or does not exist
    def feature(feature: '')
      trace.debug('Session') { "Querying feature \"#{feature}\""}
      feature = http_get path: "#{@location}/features/#{feature}"
      trace.info('Session') { "Supported feature: #{feature}" }
      feature
    end

    # Queries the CIC Server for the currently connected session.
    #
    # @return [Hash] A Hash representation of the station
    # @raise [StationNotFoundError] when no station was found
    def station
      begin
        trace.debug('Session') { "Querying existing station connection" }
        station = http_get path: "#{@location}/station"
        trace.info('Session') { "Connected Station: #{station}" }
        station
      rescue HTTP::NotFoundError => e
        error = JSON.parse(e.message).keys2sym
        raise StationNotFoundError if error[:errorId] == '-2147221496'
        raise e
      end
    end

    # Connects to the given station
    #
    # @param station [Ic::StationSettings] a Hash representing the station
    # @raise [StationNotFoundError] when no station was found
    # @raise [KeyError]             when no location was retrieved
    def station=(station)
      if station.nil?
        # Disconnect from the current station
        trace.debug('Session') { 'Disconnecting from all stations' }
        http_delete path: "#{@location}/station", session: self
      else
        trace.debug('Session') { "Connecting to station #{station}" }
        begin
          station_info = http_put path: "#{@location}/station", data: station, session: self
          trace.info('Session') { "Successfully Connected to Station: #{station_info}" }
          raise KeyError, 'location'  unless (station.location = station_info[:location])
        rescue HTTP::NotFoundError => e
          error = JSON.parse(e.message).keys2sym
          raise StationNotFoundError, station[:workstation] || station[:remoteNumber] if error[:errorId] == '-2147221496'
          raise e
        end
      end
    end

    # Queries the CIC server for an authentication token.
    #
    # @param seed [string] The seed for the token
    # @return [string]     The authentication token
    # @raise [StationNotFoundError] when no token could be calculated
    def unique_auth_token(seed: '')
      begin
        trace.debug('Session') { 'Requesting a Unique Authentication Token' }
        token = http_post path: "#{@location}/unique-auth-token", data: { authTokenSeed: seed}, session: self
        trace.info('Session') { "Unique Authentication Token: #{token}" }
        token[:authToken]
      rescue HTTP::NotFoundError => e
        error = JSON.parse(e.message).keys2sym
        raise StationNotFoundError if error[:errorId] == '-2147221496'
        raise e
      end
    end

    # Acquires licenses from the CIC Server
    #
    # @param licenses [Array<#id, string>] Licenses to acquire
    # @return [Array<License>]             Acquired licenses
    # @raise [ArgumentError] when no licenses could be retrieved
    def acquire_licenses(licenses: [])
      return if licenses.empty?
      licenses = [ licenses ] unless licenses.respond_to? :collect
      data = {
          licenseList: licenses.collect {|license| license.respond_to?(:id) ? license.id : license }
      }
      results = http_post path: "/icws/#{@id}/licenses", data: data
      raise ArgumentError, 'licenseOperationResultList' unless results[:licenseOperationResultList]
      results[:licenseOperationResultList].collect { |item| License.new(item.merge(session: self)) }
    end

    # Replaces licenses from the CIC Server
    #
    # @param licenses [Array<#id, string>] Licenses to replace
    # @return [Array<License>]             Replaced licenses
    # @raise [ArgumentError] when no licenses could be retrieved
    def replace_licenses(*licenses)
      return if licenses.empty?
      data = {
          licenseList: licenses.collect {|license| license.respond_to?(:id) ? license.id : license }
      }
      results = http_put path: "/icws/#{@id}/licenses", data: data
      raise ArgumentError, 'licenseOperationResultList' unless results[:licenseOperationResultList]
      results[:licenseOperationResultList].collect { |item| License.new(item.merge(session: self)) }
    end

    # Releases all licenses from the CIC Server
    def release_all_licenses
      http_delete path: "/icws/#{@id}/licenses"
    end

    # String representation of a Session
    #
    # @return [String] String representation
    def to_s
      connected? ? id : ''
    end

    private

    # Queries a CIC server for new messages
    #
    # The server is querie every @message_poll_frequency seconds as specified
    # when initializing the Session object.
    #
    # When messages are received, it dispatches the messages to the Session's subscribers.
    #
    # The inner threqd ends when the session is disconnected
    def poll_messages
      @message_poll_active = true
      @message_thread = Thread.new do
        begin
          if count_observers > 0
            trace.debug('messages') {'Polling server for messages'}
            results = http_get path: "/icws/#{@id}/messaging/messages"
            raise ArgumentError, 'values' unless results[:values]
            unless results[:values].empty?
              changed
              results[:values].each do |value|
                trace.debug('messages') { "Received data: #{value}"}
                message = Message.from_json(value)
                trace.debug('messages') { "Received message: #{message}"}
                notify_observers(message: message)
              end
            end
          end
          sleep(@message_poll_frequency)
        end while @message_poll_active
        trace.info('messages') {'Stopped polling server for messages'}
      end
    end
  end
end
