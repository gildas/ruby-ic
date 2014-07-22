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
        request.content_type = 'application/json'
        request.body = data.to_json
        response = transport.request(request)
      rescue
        puts "Error while connecting: #{$!}"
        raise
      end

      puts "Response #{response.code} #{response.message}: #{response.body}"
      case response
        when Net::HTTPRedirection
        when Net::HTTPServiceUnavailable
          json = JSON.parse(response.body)
          puts JSON.pretty_generate json
          self
        when Net::HTTPSuccess
        else
          raise response
      end

    end

    def connected?
      ! @id.nil?
    end
  end
end
