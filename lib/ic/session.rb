require 'json'
require 'httpclient'
require 'ic/helpers'
require 'ic/http_statuses'
require 'ic/exceptions'
require 'ic/logger'

module Ic
  class Session
    MAX_REDIRECTIONS = 5

    attr_reader :id, :application, :server, :port, :user, :scheme, :language

    def initialize(options = {})
      @application = options[:application]      || 'icws client'
      @server      = options[:server]           || 'localhost'
      @scheme      = options[:scheme]           || 'https'
      @port        = options[:port]             || 8019
      @language    = options[:language]         || 'en-us'
      raise MissingArgumentError, 'user'     unless @user     = options[:user]
      raise MissingArgumentError, 'password' unless @password = options[:password]

      @logger = Ic::Logger.create(options)
      proxy        = ENV['HTTP_PROXY'] || options[:proxy]
      @client      = HTTPClient.new(proxy)
      @uri         = URI.parse("#{@scheme}://#{@server}:#{@port}")
      @token       = nil
      @id          = nil
      @logger.info('Session') { "Will connect to #{@uri}" }
    end

    def self.connect(options = {})
      Session.new(options).connect
    end

    def connect
      disconnect if connected?
      data = {
      '__type'          => 'urn:inin.com:connection:icAuthConnectionRequestSettings',
      'applicationName' => @application,
      'userID'          => @user,
      'password'        => @password,
      }
      alternate_server_index = 0
      server = @server
      while true do
        @uri = URI.parse("#{@scheme}://#{server}:#{@port}")
        @logger.info('Session') { "Connecting application \"#{@application}\" to #{@uri} as #{@user}" }
        response = http :post, :path => '/connection', :data => data
        if response.redirect? || HTTP::Status::SERVICE_UNAVAILABLE == response.status
          @logger.warn('Session') { "We need to check other servers" }
          data = JSON.parse(response.body)
          @logger.info('Session') { "alternate servers: #{}JSON.pretty_generate data}" }
          server = data['alternateHostList'].first
          raise TooManyRedirectionsError if alternate_server_index >= MAX_REDIRECTIONS
          alternate_server_index += 1
        else
          @server = server
          break
        end
      end

      if response.ok?
        # cookies are managed automatically by the httpclient gem
        @id    = response.header['ININ-ICWS-Session-ID'].first if response.header['ININ-ICWS-Session-ID']
        @token = response.header['ININ-ICWS-CSRF-Token'].first if response.header['ININ-ICWS-CSRF-Token']
        @logger.info("Session##{@id}") { "Successfully Connected to Session #{@id}, token=\"#{@token}\"" }
        self
      else
        @logger.error('Session') { "Failure while connecting to #{@uri}: #{response}"}
        case response.status
          when HTTP::Status::BAD_REQUEST
            # The response can be something like:
            #   {"errorId":"error.request.connection.authenticationFailure","errorCode":-2147221503,"message":"The authentication process failed."}
            error = JSON.parse(response.body)
            raise AuthenticationError if error['errorId']   == 'error.request.connection.authenticationFailure'
            raise AuthenticationError if error['errorCode'] == -2147221503
            raise RuntimeError, response
          when HTTP::Status::UNAUTHORIZED
            error = JSON.parse(response.body)
            raise SessionIDRequiredError, response.header.request_uri if error['errorCode'] == 1
             # TODO: Add some reconnection code, when it makes sense
          else
            error = JSON.parse(response.body)
            raise RuntimeError, error
        end
      end
    end

    def disconnect
      return if ! connected?
      @logger.info("Session##{@id}") { "Disconnecting from #{@server}" }
      response = http :delete, :path => "/#{@id}/connection"
      if response.ok?
        @logger.info("Session##{@id}") { "Successfully disconnected from #{@server}" }
        @cookie = nil
        @id     = nil
        @token  = nil
      else
        if response.body
          error = JSON.parse(response.body)
          raise RuntimeError, error
        else
          raise RuntimeError, response.status
        end
      end
    end

    def server_version
      response = http :get, :path => '/connection/version'
      if response.ok?
        @logger.info("Session##{@id}") { "Server version: #{response.body}" }
        JSON.parse(response.body).keys2sym
      else
        if response.body
          error = JSON.parse(response.body)
          @logger.error("Session##{@id}") { "Failure: #{error}" }
          raise RuntimeError, error
        else
          @logger.error("Session##{@id}") { "Failure: #{response.status}" }
          raise RuntimeError, response.status
        end
      end
    end

    def server_features
      response = http :get, :path => '/connection/features'
      if response.ok
        data = JSON.parse(response.body)
        raise ArgumentError, "featureInfoList" if ! data['featureInfoList']
        data['featureInfoList']
      else
        if response.body
          error = JSON.parse(response.body)
          raise RuntimeError, error
        else
          raise RuntimeError, response.status
        end
      end
    end

    def connected?
      ! @id.nil?
    end

    def to_s
      connected? ? "Session #{@id} connected to #{@server} as #{@user}" : ''
    end

    private
    def http(verb, options = {})
      raise MissingArgumentError, ':path' if !options[:path]
      url = "#{@uri}/icws#{options[:path]}"
      headers = {}
      headers['Accept-Language']      = options[:language] || @language
      headers['ININ-ICWS-CSRF-Token'] = options[:token]    || @token
      @client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE # Only if turned on, we should verify by default
      @client.ssl_config.verify_callback = @client.ssl_config.method(:sample_verify_callback)
      # TODO: Timeout

      body = nil
      if (options[:data])
        headers['Content-Type'] = 'application/json'
        body = options[:data].to_json
      end
      @logger.info('HTTP')  { "Sending request to #{url}" }
      @logger.debug('HTTP') { "  SSL verify mode: #{@client.ssl_config.verify_mode}" }
      @logger.debug('HTTP') {"HTTP traffic <<<<<"}
      @client.debug_dev = @logger if @logger.debug?
      case verb
        when :get    then response = @client.get(url, body, headers)
        when :post   then response = @client.post(url, body, headers)
        when :delete then response = @client.delete(url, body, headers)
        when :put    then response = @client.put(url, body, headers)
        else raise ArgumentError, 'verb'
      end
      @client.debug_dev = nil if @logger.debug?
      @logger.debug('HTTP') {"HTTP traffic >>>>>"}
      @logger.debug('HTTP') { "Response: #{response.status} #{response.reason}" }
      response
    end
  end
end
