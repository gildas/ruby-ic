require 'json'
require 'httpclient'
require 'ic/http_exceptions'
require 'ic/http_statuses'
require 'ic/logger'

module Ic
  module HTTP
    module Requestor

      attr_reader :client
      attr_writer :client

      def http_get(options={})    ;  @client.request :get,    options ;  end
      def http_post(options={})   ;  @client.request :post,   options ;  end
      def http_delete(options={}) ;  @client.request :delete, options ;  end
      def http_put(options={})    ;  @client.request :put,    options ;  end
    end

    class Client
      include Traceable
      attr_reader :server, :language

      def initialize(options = {})
        initialize_logger( options)
        @server      = options[:server]           || 'localhost'
        @scheme      = options[:scheme]           || 'https'
        @port        = options[:port]             || 8019
        @uri         = URI.parse("#{@scheme}://#{@server}:#{@port}")
        @language    = options[:language]         || 'en-us'
        @token       = nil
        proxy        = ENV['HTTP_PROXY'] || options[:proxy]
        @client      = HTTPClient.new(proxy)
      end

      def server=(server)
        @server = server
        @uri    = URI.parse("#{@scheme}://#{@server}:#{@port}")
      end

      def get(options = {})
        request :get, options
      end

      def post(options = {})
        request :post, options
      end

      def delete(options = {})
        request :delete, options
      end

      def put(options = {})
        request :put, options
      end

      def request(verb, options = {})
        # cookies are managed automatically by the httpclient gem
        raise MissingArgumentError, ':path' unless options[:path]
        self.server = options[:server] if options[:server]
        url = "#{@uri}#{options[:path]}"
        headers = {}
        headers['Accept-Language']      = options[:language] || @language
        headers['ININ-ICWS-CSRF-Token'] = options[:token]    || @token
        @client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE # Only if turned on, we should verify by default
        @client.ssl_config.verify_callback = @client.ssl_config.method(:sample_verify_callback)
        # TODO: Timeout

        body      = nil
        object_id = nil
        if options[:data]
          headers['Content-Type'] = 'application/json'
          body = options[:data].to_json
          object_id = options[:data].id      if options[:data].respond_to? :id
          session   = options[:data].session if options[:data].respond_to?(:session) && options[:data].session
        end
        trace.info('HTTP')  { "Sending #{verb} request to #{url}" }
        trace.debug('HTTP') { "  SSL verify mode: #{@client.ssl_config.verify_mode}" }
        trace.debug('HTTP') {'HTTP traffic <<<<<'}
        @client.debug_dev = logger if trace.debug?
        case verb
          when :get    then response = @client.get(url, body, headers)
          when :post   then response = @client.post(url, body, headers)
          when :delete then response = @client.delete(url, body, headers)
          when :put    then response = @client.put(url, body, headers)
          else raise ArgumentError, 'verb'
        end
        @client.debug_dev = nil if trace.debug?
        trace.debug('HTTP') {'HTTP traffic >>>>>'}
        trace.debug('HTTP') { "Response: #{response.status} #{response.reason}" }
        if response.redirect? || HTTP::Status::SERVICE_UNAVAILABLE == response.status
          trace.warn('HTTP') { 'Host wants us to redirect' }
          targets = JSON.parse(response.content).keys2sym
          raise KeyError, 'alternateHostList' unless targets[:alternateHostList]
          raise HTTP::WantRedirection, targets[:alternateHostList]
        elsif response.ok?
          data = {}
          if response.content.size > 0
            data.merge! JSON.parse(response.content).keys2sym
            @token = data[:csrfToken] if data[:csrfToken]
            data[:location] = response.header['Location'].first if response.header['Location'] && !response.header['Location'].empty?
            trace.debug('HTTP') { "Token?: #{data[:csrfToken]}"}
          end
          data[:content_type] = response.header['Content-Type'].first
          data[:location] = response.header['Location'].first if response.header['Location'] && !response.header['Location'].empty?
          trace.debug('HTTP') { "Content Type: #{data[:content_type]}, location?: #{data[:location]}"}
          return data
        else
          trace.error('HTTP') { "HTTP Failure: #{response.status} #{response.reason}" }
          error = { session: session, id: object_id }
          error.merge!(JSON.parse(response.content).keys2sym) if response.content.size > 0
          trace.error('HTTP') { "ICWS Failure: session=#{error[:session]}, id=#{error[:errorId]}, code=#{error[:errorCode]}, message=\"#{error[:message]}\"" }
          case response.status
            when HTTP::Status::BAD_REQUEST
              # The response can be something like:
              #   {"errorId":"error.request.connection.authenticationFailure","errorCode":-2147221503,"message":"The authentication process failed."}
              raise HTTP::AuthenticationError          if error[:errorId]   == 'error.request.connection.authenticationFailure'
              raise HTTP::AuthenticationError          if error[:errorCode] == -2147221503 # There was no errorId in CIC < 4.0.6
              raise HTTP::NotFoundError, error.to_json if error[:errorId]   == '-2147221496'
              raise HTTP::BadRequestError, response
            when HTTP::Status::UNAUTHORIZED
              raise SessionIdExpectedError              if error[:errorCode] == 1
              raise AuthTokenExpectedError              if error[:errorCode] == 2
              if error[:errorCode] == -2147221499
                raise InvalidSessionIdError, session.id   if session.respond_to? :id
                raise InvalidSessionIdError
              end
              # TODO: Add some reconnection code, when it makes sense
              raise HTTP::UnauthorizedError, error.to_json
            when HTTP::Status::NOT_FOUND
              raise HTTP::NotFoundError, error.to_json
            else
              raise HTTP::HTTPError, error.to_json
          end
        end
      end
    end
  end
end