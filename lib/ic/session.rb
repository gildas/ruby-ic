require 'json'
require 'ic/helpers'
require 'ic/http'
require 'ic/exceptions'
require 'ic/logger'

module Ic
  class Session
    MAX_REDIRECTIONS = 5

    attr_reader :id, :application, :user, :user_display

    def initialize(options = {})
      raise MissingArgumentError, 'user'     unless (@user     = options[:user])
      raise MissingArgumentError, 'password' unless (@password = options[:password])
      @user_display = @user
      @application  = options[:application] || 'icws client'
      @logger       = options[:logger]      || Ic::Logger.create(options)
      @client       = options[:httpclient]  || Ic::HTTP::Client.new(options.merge(logger: @logger))
      @id           = nil
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
          session_info = @client.post server: server, path: '/connection', data: data
          raise KeyError, 'sessionId' unless session_info[:sessionId]
          raise KeyError, 'csrfToken' unless session_info[:csrfToken]
          @id            = session_info[:sessionId]
          @user_display |= session_info[:userDisplayName]
          @logger.info("Session##{@id}") { "Successfully Connected to Session #{@id}" }
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
      @logger.info("Session##{@id}") { "Disconnecting from #{@client.server}" }
      @client.delete path: "/#{@id}/connection"
      @logger.info("Session##{@id}") { "Successfully disconnected from #{@client.server}" }
      @id = nil
      self
    end

    def server
      @client.server
    end

    def language
      @client.language
    end

    def version
      version = @client.get path: '/connection/version'
      @logger.info('Session') { "Server version: #{version}" }
      version
    end

    def features
      features = @client.get path: '/connection/features'
      @logger.info('Session') { "Server features: #{features}" }
      raise ArgumentError, 'featureInfoList' unless features[:featureInfoList]
      features[:featureInfoList]
    end

    def feature?(feature)
      begin
        @logger.debug('Session') { "Querying feature \"#{feature}\""}
        feature = @client.get path: "/connection/features/#{feature}"
        @logger.info('Session') { "Supported feature: #{feature}" }
        true
      rescue HTTP::BadRequestError => e
        @logger.info('Session') { "Unsupported feature: #{feature}, error: #{e.message}"}
        false
      end
    end

    def connected?
      ! @id.nil?
    end

    def to_s
      connected? ? "Session #{@id} connected to #{@client.server} as #{@user}" : ''
    end
  end
end
