require 'net/http'
require 'net/https'
require 'json'
require 'ic/exceptions'

module Ic
  class Session
    attr_reader :id, :application_name, :server, :port, :user, :scheme, :language

    def initialize(options = {})
      @application = options[:application] || 'icws client'
      @server      = options[:server]           || 'localhost'
      @scheme      = options[:scheme]           || 'https'
      @port        = options[:port]             || 8019
      @language    = options[:language]         || 'en-us'
      raise MissingArgumentError, 'user'     unless @user     = options[:user]
      raise MissingArgumentError, 'password' unless @password = options[:password]

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
      transport = Net::HTTP.new(@uri.host, @uri.port)
      transport.use_ssl = @scheme.downcase == 'https'
      transport.verify_mode = OpenSSL::SSL::VERIFY_NONE
      transport.open_timeout = 5
      transport.set_debug_output($stdout)
      puts "Connecting to #{@uri} as #{@user}..."
      puts data.to_json
      begin
        request = Net::HTTP::Post.new(@uri.path + '/icws/connection')
        request['Accept-Language'] = @language
        request['ININ-ICWS-CSRF-Token'] = @token if @token
        request.content_type = 'application/json'
        request.body = data.to_json
        response = transport.request(request)
      rescue
        puts "Error while connecting: #{$!}"
        raise
      end

      puts "Response #{response.code} #{response.message}: #{response.body}"
      case response
        when Net::HTTPBadRequest
          # The response can be something like:
          #   {"errorId":"error.request.connection.authenticationFailure","errorCode":-2147221503,"message":"The authentication process failed."}
          error = JSON.parse(response.body)
          raise AuthenticationError if error['errorId'] == "error.request.connection.authenticationFailure"
          raise RuntimeError, response
        when Net::HTTPRedirection
        when Net::HTTPServiceUnavailable
          json = JSON.parse(response.body)
          puts JSON.pretty_generate json
          self
        when Net::HTTPUnauthorized
          puts "Authorization expired" #TODO: Add some reconnection code
        when Net::HTTPSuccess
          puts "Success!!!"

          @cookie   = response['Set-Cookie']           if response['Set-Cookie']
          @id       = response['ININ-ICWS-Session-ID'] if response['ININ-ICWS-Session-ID']
          @token    = response['ININ-ICWS-CSRF-Token'] if response['ININ-ICWS-CSRF-Token']
          @password = nil
          puts "Cookie    : \"#{@cookie}\""
          puts "Session Id: \"#{@id}\""
          puts "Token     : \"#{@token}\""
          self
        else
          error = JSON.parse(response.body)
          raise RuntimeError, error
      end
    end

    def connected?
      ! @id.nil?
    end

    def to_s
      connected? ? "Session #{@id} connected to #{@server} as #{@user}" : ''
    end
  end
end
