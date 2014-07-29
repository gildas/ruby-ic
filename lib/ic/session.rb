require 'json'
require 'ic/helpers'
require 'ic/http'
require 'ic/exceptions'
require 'ic/logger'

module Ic
  class Session
    include Traceable
    MAX_REDIRECTIONS = 5

    BASE_LOCATION = '/icws/connection'

    attr_reader :id, :application, :user, :user_display, :client

    def initialize(options = {})
      initialize_logger( options)
      raise MissingArgumentError, 'user'     unless (@user     = options[:user])
      raise MissingArgumentError, 'password' unless (@password = options[:password])
      @user_display = @user
      @application  = options[:application] || 'icws client'
      @client       = options[:httpclient]  || Ic::HTTP::Client.new(options.merge(log_to: logger))
      @id           = nil
      @location     = BASE_LOCATION
    end

    def self.connect(options = {})
      Session.new(options).connect
    end

    def connect
      disconnect if connected?
      data = {
        __type:          'urn:inin.com:connection:icAuthConnectionRequestSettings',
        applicationName: @application,
        userID:          @user,
        password:        @password,
      }
      alternate_server_index = 0
      server = @client.server
      loop do
        trace.info('Session') { "Connecting application \"#{@application}\" to #{server} as #{@user}" }
        begin
          session_info = @client.post server: server, path: BASE_LOCATION, data: data
          raise KeyError, 'sessionId' unless (@id       = session_info[:sessionId])
          raise KeyError, 'location'  unless (@location = session_info[:location])
          raise KeyError, 'csrfToken' unless session_info[:csrfToken]
          @user_display ||= session_info[:userDisplayName]
          trace.info("Session##{@id}") { "Successfully Connected to Session #{@id}, located at: #{@location}" }
          return self
        rescue HTTP::WantRedirection => e
          trace.warn('Session') { 'We need to check other servers' }
          trace.info('Session') { "alternate servers: #{JSON.pretty_generate(e.message)}" }
          server = e.message.first
          raise TooManyRedirectionsError if alternate_server_index >= MAX_REDIRECTIONS
          alternate_server_index += 1
        end
      end
    end

    def disconnect
      return self unless connected?
      trace.debug("Session##{@id}") { "Disconnecting from #{@client.server}" }
      @client.delete path: location, session: self
      trace.info("Session##{@id}") { "Successfully disconnected from #{@client.server}" }
      @id = nil
      self
    end

    def connected?
      ! @id.nil?
    end

    def location
      connected? ? @location : '/icws/connection'
    end

    def server
      @client.server
    end

    def language
      @client.language
    end

    def version
      version = @client.get path: "#{BASE_LOCATION}/version"
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
        feature = @client.get path: "#{BASE_LOCATION}/features/#{feature}"
        trace.info('Session') { "Supported feature: #{feature}" }
        true
      rescue HTTP::BadRequestError => e
        trace.info('Session') { "Unsupported feature: #{feature}, error: #{e.message}"}
        false
      end
    end

    def feature(feature)
      trace.debug('Session') { "Querying feature \"#{feature}\""}
      feature = @client.get path: "#{BASE_LOCATION}/features/#{feature}"
      trace.info('Session') { "Supported feature: #{feature}" }
      feature
    end

    def station
      begin
        trace.debug("Session##{@id}") { "Querying existing station connection" }
        station = @client.get path: "#{location}/station"
        trace.info("Session##{@id}") { "Connected Station: #{station}" }
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
        trace.debug("Session##{@id}") { 'Disconnecting from all stations' }
        @client.delete path: "#{location}/station", session: self
      else
        trace.debug("Session##{@id}") { "Connecting to station #{station}" }
        begin
          station_info = @client.put path: "#{location}/station", data: station, session: self
          trace.info("Session##{@id}") { "Successfully Connected to Station: #{station_info}" }
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
        trace.debug("Session##{@id}") { "Requesting a Unique Authentication Token" }
        token = @client.post path: "#{location}/unique-auth-token", data: { authTokenSeed: seed}, session: self
        trace.info("Session##{@id}") { "Unique Authentication Token: #{token}" }
        token[:authToken]
      rescue HTTP::NotFoundError => e
        error = JSON.parse(e.message).keys2sym
        raise StationNotFoundError if error[:errorId] == '-2147221496'
        raise e
      end
    end

    def to_s
      connected? ? id : ''
    end
  end
end
