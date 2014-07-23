require 'json'
require 'httpclient'
require 'ic/http_statuses'
require 'ic/exceptions'

module Ic
  class Session
    attr_reader :id, :application_name, :server, :port, :user, :scheme, :language

    def initialize(options = {})
      @application = options[:application]      || 'icws client'
      @server      = options[:server]           || 'localhost'
      @scheme      = options[:scheme]           || 'https'
      @port        = options[:port]             || 8019
      @language    = options[:language]         || 'en-us'
      raise MissingArgumentError, 'user'     unless @user     = options[:user]
      raise MissingArgumentError, 'password' unless @password = options[:password]

      proxy        = ENV['HTTP_PROXY'] || options[:proxy]
      @client      = HTTPClient.new(proxy)
      @uri         = URI.parse("#{@scheme}://#{@server}:#{@port}")
      @token       = nil
      @id          = nil
    end

    def self.connect(options = {})
      Session.new(options).connect
    end

    def connect
      data = {
      '__type'          => 'urn:inin.com:connection:icAuthConnectionRequestSettings',
      'applicationName' => @application,
      'userID'          => @user,
      'password'        => @password,
      }
      puts "Connecting to #{@uri} as #{@user}..."
      puts data.to_json
      begin
        response = http :post, :path => '/connection', :data => data
      rescue
        puts "Error while connecting: #{$!}"
        raise
      end

      puts "Response: #{response.inspect}"
      if response.redirect? || HTTP::Status::SERVICE_UNAVAILABLE == response.status
        puts "We need to check other servers"
        json = JSON.parse(response.body)
        puts JSON.pretty_generate json
      end

      if response.ok?
        if response.header['set-cookie']
          response.header['set-cookie'].each do |value|
            puts "Cookie: #{value}"
          end
        end
        puts "Body: [#{response.body}]"
        @cookie   = response.header['set-cookie'].first           if response.header['set-cookie']
        @id       = response.header['ININ-ICWS-Session-ID'].first if response.header['ININ-ICWS-Session-ID']
        @token    = response.header['ININ-ICWS-CSRF-Token'].first if response.header['ININ-ICWS-CSRF-Token']
        @password = nil
        puts "Cookie    : \"#{@cookie}\""
        puts "Session Id: \"#{@id}\""
        puts "Token     : \"#{@token}\""
        self
      else
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

    def connected?
      ! @id.nil?
    end

    def to_s
      connected? ? "Session #{@id} connected to #{@server} as #{@user}" : ''
    end

    private
    def http(verb, options = {})
      raise MissingArgumentError, ':path' if !options[:path]
      headers = {}
      headers['Accept-Language']      = options[:language] || @language
      headers['ININ-ICWS-CSRF-Token'] = options[:token]    || @token
      @client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE # Only if turned on, we should verify by default
      # TODO: Timeout

      body = nil
      if (options[:data])
        headers['Content-Type'] = 'application/json'
        body = options[:data].to_json
      end
      @client.debug_dev = STDERR if options[:debug] || $DEBUG
      case verb
        when :get    then response = @client.get("#{@uri}/icws#{options[:path]}", body, headers)
        when :post   then response = @client.post("#{@uri}/icws#{options[:path]}", body, headers)
        when :delete then response = @client.delete("#{@uri}/icws#{options[:path]}", body, headers)
        when :put    then response = @client.put("#{@uri}/icws#{options[:path]}", body, headers)
        else raise ArgumentError, 'verb'
      end
      @client.debug_dev = nil if options[:debug] || $DEBUG
      response
    end
  end
end
