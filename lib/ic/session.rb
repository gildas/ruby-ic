require 'json'
require 'ic/helpers'
require 'ic/http'
require 'ic/exceptions'
require 'ic/logger'

module Ic
  class Session
    MAX_REDIRECTIONS = 5

    BASE_LOCATION = '/icws/connection'

    attr_reader :id, :application, :user, :user_display

    def initialize(options = {})
      raise MissingArgumentError, 'user'     unless (@user     = options[:user])
      raise MissingArgumentError, 'password' unless (@password = options[:password])
      @user_display = @user
      @application  = options[:application] || 'icws client'
      @logger       = options[:logger]      || Ic::Logger.create(options)
      @client       = options[:httpclient]  || Ic::HTTP::Client.new(options.merge(logger: @logger))
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
        @logger.info('Session') { "Connecting application \"#{@application}\" to #{server} as #{@user}" }
        begin
          session_info = @client.post server: server, path: BASE_LOCATION, data: data
          raise KeyError, 'sessionId' unless (@id       = session_info[:sessionId])
          raise KeyError, 'location'  unless (@location = session_info[:location])
          raise KeyError, 'csrfToken' unless session_info[:csrfToken]
          @user_display ||= session_info[:userDisplayName]
          @logger.info("Session##{@id}") { "Successfully Connected to Session #{@id}, located at: #{@location}" }
          return self
        rescue HTTP::WantRedirection => e
          @logger.warn('Session') { 'We need to check other servers' }
          @logger.info('Session') { "alternate servers: #{JSON.pretty_generate(e.message)}" }
          server = e.message.first
          raise TooManyRedirectionsError if alternate_server_index >= MAX_REDIRECTIONS
          alternate_server_index += 1
        end
      end
    end

    def disconnect
      return self unless connected?
      @logger.debug("Session##{@id}") { "Disconnecting from #{@client.server}" }
      @client.delete path: location, session: self
      @logger.info("Session##{@id}") { "Successfully disconnected from #{@client.server}" }
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
      @logger.info('Session') { "Server version: #{version}" }
      version
    end

    def features
      features = @client.get path: "#{BASE_LOCATION}/features"
      @logger.info('Session') { "Server features: #{features}" }
      raise ArgumentError, 'featureInfoList' unless features[:featureInfoList]
      features[:featureInfoList]
    end

    def feature?(feature)
      begin
        @logger.debug('Session') { "Querying feature \"#{feature}\""}
        feature = @client.get path: "#{BASE_LOCATION}/features/#{feature}"
        @logger.info('Session') { "Supported feature: #{feature}" }
        true
      rescue HTTP::BadRequestError => e
        @logger.info('Session') { "Unsupported feature: #{feature}, error: #{e.message}"}
        false
      end
    end

    def feature(feature)
      @logger.debug('Session') { "Querying feature \"#{feature}\""}
      feature = @client.get path: "#{BASE_LOCATION}/features/#{feature}"
      @logger.info('Session') { "Supported feature: #{feature}" }
      feature
    end

    def station(options = {})
      if options.empty?
        begin
          @logger.debug("Session##{@id}") { "Querying existing station connection" }
          station = @client.get path: "#{location}/station"
          @logger.info('Session') { "Connected Station: #{station}" }
          station
        rescue HTTP::NotFoundError => e
          error = JSON.parse(e.message).keys2sym
          raise StationNotFoundError if error[:errorId] == '-2147221496'
          raise e
        end
      else
        @logger.debug("Session##{@id}") { "Connecting to station #{options.to_json}" }
        station = {}
        case options[:type]
          when :remote_number
            station[:__type] = 'urn:inin.com:connection:remoteNumberSettings'
            raise MissingArgumentError, 'number' unless (station[:remoteNumber] = options[:number])
            station[:persistentConnection] ||= options[:persistent]
          when :remote_station, :remote_workstation
            station[:__type] = 'urn:inin.com:connection:remoteWorkstationSettings'
            raise MissingArgumentError, 'station' unless (station[:workstation] = options[:workstation] || options[:station])
            station[:number] ||= options[:number]
          when :station, :workstation
            station[:__type] = 'urn:inin.com:connection:workstationSettings'
            raise MissingArgumentError, 'station' unless (station[:workstation] = options[:workstation] || options[:station])
          else
            raise ArgumentError, 'type'
        end
        station[:readyForInteractions] ||= options[:ready] || options[:readyForInteractions]
        begin
          station_info = @client.put path: "#{location}/station", data: station
          @logger.info('Session') { "Successfully Connected to Station: #{station_info}" }
          station_info
        rescue HTTP::NotFoundError => e
          error = JSON.parse(e.message).keys2sym
          raise StationNotFoundError, station[:workstation] || station[:remoteNumber] if error[:errorId] == '-2147221496'
          raise e
        end
      end
    end

    def to_s
      connected? ? "Session #{@id} connected to #{@client.server} as #{@user}" : ''
    end
  end
end
