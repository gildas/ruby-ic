require 'json'
require 'observer'
require 'ic/helpers'
require 'ic/http'
require 'ic/exceptions'
require 'ic/logger'
require 'ic/message'
require 'ic/observer'
require 'ic/user'
require 'ic/license'

module Ic
  # Session objects are used to manage connections to a CIC Server
  class Session
    include Observable
    include Traceable
    include HTTP::Requestor

    MAX_REDIRECTIONS = 5

    BASE_LOCATION = '/icws/connection'

    attr_reader :id, :application, :user, :client

    def initialize(options = {})
      if options[:from]
        config = {}
        case options[:from]
          when String             then File.open(options[:from]) { |file| config = JSON.parse(file.read) }
          when File, StringIO, IO then  config = JSON.parse(options[:from].read)
          else raise InvalidArgumentError, 'from'
        end
        options = config.keys2sym.merge(options)
      end
      raise MissingArgumentError, 'user'     unless options[:user]
      raise MissingArgumentError, 'password' unless (@password = options[:password])
      self.create_logger(options)
      @application            = options[:application] || 'icws client'
      self.client             = options[:httpclient]  || Ic::HTTP::Client.new(options.merge(log_to: logger))
      @id                     = nil
      @location               = BASE_LOCATION
      @user                   = User.new(session: self, id: options[:user])
      @message_poll_frequency = options[:poll_frequency] || 1
      @message_thread         = nil
      @message_poll_active    = false
    end

    def self.connect(options = {})
      Session.new(options).connect
    end

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
          session_info = http_post server: server, path: BASE_LOCATION, data: data
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

    def disconnect
      return self unless connected?
      trace.info('messages') { "Stopping Message polling" }
      @message_poll_active = false
      @message_thread.join
      trace.debug('Session') { "Disconnecting from #{client.server}" }
      http_delete path: location, session: self
      trace.info('Session') { "Successfully disconnected from #{client.server}" }
      logger.remove_context(session: @id)
      @id = nil
      self
    end

    def connected?
      ! @id.nil?
    end

    def location
      connected? ? @location : BASE_LOCATION
    end

    def server
      @client.server
    end

    def language
      @client.language
    end

    def version
      version = http_get path: "#{BASE_LOCATION}/version"
      trace.info('Session') { "Server version: #{version}" }
      version
    end

    def features
      features = @client.get path: "#{BASE_LOCATION}/features"
      trace.info('Session') { "Server features: #{features}" }
      raise ArgumentError, 'featureInfoList' unless features[:featureInfoList]
      features[:featureInfoList]
    end

    def feature?(feature)
      begin
        trace.debug('Session') { "Querying feature \"#{feature}\""}
        feature = http_get path: "#{BASE_LOCATION}/features/#{feature}"
        trace.info('Session') { "Supported feature: #{feature}" }
        true
      rescue HTTP::BadRequestError => e
        trace.info('Session') { "Unsupported feature: #{feature}, error: #{e.message}"}
        false
      end
    end

    def feature(feature)
      trace.debug('Session') { "Querying feature \"#{feature}\""}
      feature = http_get path: "#{BASE_LOCATION}/features/#{feature}"
      trace.info('Session') { "Supported feature: #{feature}" }
      feature
    end

    def station
      begin
        trace.debug('Session') { "Querying existing station connection" }
        station = http_get path: "#{location}/station"
        trace.info('Session') { "Connected Station: #{station}" }
        station
      rescue HTTP::NotFoundError => e
        error = JSON.parse(e.message).keys2sym
        raise StationNotFoundError if error[:errorId] == '-2147221496'
        raise e
      end
    end

    def station=(station)
      if station.nil?
        # Disconnect from the current station
        trace.debug('Session') { 'Disconnecting from all stations' }
        http_delete path: "#{location}/station", session: self
      else
        trace.debug('Session') { "Connecting to station #{station}" }
        begin
          station_info = http_put path: "#{location}/station", data: station, session: self
          trace.info('Session') { "Successfully Connected to Station: #{station_info}" }
          raise KeyError, 'location'  unless (station.location = station_info[:location])
        rescue HTTP::NotFoundError => e
          error = JSON.parse(e.message).keys2sym
          raise StationNotFoundError, station[:workstation] || station[:remoteNumber] if error[:errorId] == '-2147221496'
          raise e
        end
      end
    end

    def unique_auth_token(seed)
      begin
        trace.debug('Session') { 'Requesting a Unique Authentication Token' }
        token = http_post path: "#{location}/unique-auth-token", data: { authTokenSeed: seed}, session: self
        trace.info('Session') { "Unique Authentication Token: #{token}" }
        token[:authToken]
      rescue HTTP::NotFoundError => e
        error = JSON.parse(e.message).keys2sym
        raise StationNotFoundError if error[:errorId] == '-2147221496'
        raise e
      end
    end

    def acquire_licenses(*licenses)
      return if licenses.empty?
      data = {
          licenseList: licenses.collect {|license| license.respond_to?(:id) ? license.id : license }
      }
      results = http_post path: "/icws/#{@id}/licenses", data: data
      raise ArgumentError, 'licenseOperationResultList' unless results[:licenseOperationResultList]
      results[:licenseOperationResultList].collect { |item| License.new(item.merge(session: self)) }
    end

    def replace_licenses(*licenses)
      return if licenses.empty?
      data = {
          licenseList: licenses.collect {|license| license.respond_to?(:id) ? license.id : license }
      }
      results = http_put path: "/icws/#{@id}/licenses", data: data
      raise ArgumentError, 'licenseOperationResultList' unless results[:licenseOperationResultList]
      results[:licenseOperationResultList].collect { |item| License.new(item.merge(session: self)) }
    end

    def release_all_licenses
      http_delete path: "/icws/#{@id}/licenses"
    end

    def subscribe(message_class: nil, **options, &block)
      raise MissingArgumentError, 'message_class' if message_class.nil?
      Observer.new(session: self, message_class: message_class).start(**options, &block)
    end

    def to_s
      connected? ? id : ''
    end

    private

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
