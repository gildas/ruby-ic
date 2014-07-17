require 'net/http'
require 'net/https'
require 'json'

module Ic
  class Session
    attr_reader :id,  :application_name, :server, :port, :user, :scheme

    def initialize(options = {})
      @application_name = options[:application_name] || 'icws client'
      @server           = options[:server]           || 'localhost'
      @scheme           = options[:scheme]           || 'https'
      @port             = options[:port]             || 8019
      @user             = options[:user]     #|| throw new ArgumentError('user')
      @password         = options[:password] #|| throw new ArgumentError('password')
      @uri              = URI.parse("#{@scheme}://#{@server}:#{@port}/")
      @id               = nil
    end

    def self.connect(options = {})
      Session.new(options).connect
    end

    def connect
      data = {
      '__type'          => 'urn:inin.com:connection:icAuthConnectionRequestSettings',
      'applicationName' => @application_name,
      'userID'          => @user,
      'password'        => @password,
      }
      transport = Net::HTTP.new(@uri.host, @uri.port)
      transport.use_ssl = @scheme == 'https'
      transport.verify_mode = OpenSSL::SSL::VERIFY_NONE
      transport.set_debug_output($stdout)
      puts "Connecting to #{@uri} as #{@user}..."
      puts data.to_json
      begin
        request = Net::HTTP::Post.new(@uri.path + '/icws/connection')
        request['Accept-Language'] = 'en-us'
        #request.content_type = 'application/json'
        #request.body = data.to_json
        request.set_form_data(data)
        # Add Accept-Language: en-US (or other values)
        response = transport.request(request)
        #response = Net::HTTP.post_form(session.uri, http_options)
      rescue
        puts $!
        throw $!
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
          throw response
      end

    end

    def connected?
      ! @id.nil?
    end
  end
end
