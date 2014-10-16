require 'json'
require 'httpclient'
require 'ic/http_exceptions'
require 'ic/http_statuses'
require 'ic/logger'

module Ic
  # This module handles HTTP/HTTPS Client connections to a CIC Server via the ICWS API.
  module HTTP
    # The HTTP/HTTPS Client Connection to a CIC Server
    class Client
      include Traceable

      # @return [String] The Server to which requests are sent. Can be overriden with the keypair server: value in the options hash in {#request}.
      attr_reader :server

      # @return [String] The language that will be accepted in the response of the HTTP request
      attr_reader :language

      # Initializes a new HTTP Client
      #
      # @param server   [String] the server host name or IP address
      # @param scheme   [String] 'http' or 'https'
      # @param port     [Fixnum] the port number
      # @param language [String] the language for the connection 'lang-country', see below for codes
      # @param proxy    [String] the proxy to use if any
      # @param options  [Hash]   extra options for {Logger}
      # @option options [Fixnum] connect_timeout (60)  See {HTTPClient}
      # @option options [Fixnum] send_timeout    (120) See {HTTPClient}
      # @option options [Fixnum] receive_timeout (60)  See {HTTPClient}
      # @option options [Fixnum] connect_retry   (1)   See {HTTPClient}
      # @return         [Client] the client connection
      # @see http://www.iso.org/iso/home/standards/language_codes.htm Language codes (ISO 639-1)
      # @see http://www.iso.org/iso/country_codes.htm Country codes (ISO 3166)
      # @raise [InvalidArgumentError] when the scheme is none of 'http', 'https'.
      def initialize(server: 'localhost', scheme: 'https', port: 8019, language: 'en-us', proxy: nil, **options)
        self.create_logger(**options)
        raise InvalidArgumentError, 'scheme' unless scheme == 'http' || scheme == 'https'
        @server     = server
        @scheme     = scheme
        @port       = port
        @language   = language
        @token      = nil
        @uri        = URI.parse("#{@scheme}://#{@server}:#{@port}")
        @client     = HTTPClient.new(proxy || ENV['HTTP_PROXY'])
        @client.connect_timeout = options[:connect_timeout] ||  60
        @client.send_timeout    = options[:send_timeout]    || 120
        @client.receive_timeout = options[:receive_timeout] ||  60
        @client.connect_retry   = options[:connect_retry]   ||   1
      end

      # Assigns a new server to connect
      def server=(server)
        @server = server
        @uri    = URI.parse("#{@scheme}://#{@server}:#{@port}")
      end

      # Performs an HTTP GET request
      #
      # @param [String]   path    the URL to send the request to
      # @param [#to_json] data    an object that can ben JSONified
      # @param [Hash]     options optional arguments
      # @option options [String] :server   to use another server for this request
      # @option options [String] :language @see #initialize
      # @option options [String] :token    token received on successful connection
      # @return         [Hash] the data received from the server
      def get(path: '/', data: nil, **options)
        request(verb: :get,    path: path, data: data, **options)
      end

      # Performs an HTTP POST request
      # @param (see #get)
      def post(path: '/', data: nil, **options)
        request(verb: :post, path: path, data: data, **options)
      end

      # Performs an HTTP DELETE request
      # @param (see #get)
      def delete(path: '/', data: nil, **options)
        request(verb: :delete, path: path, data: data, **options)
      end

      # Performs an HTTP PUT request
      # @param (see #get)
      def put(path: '/', data: nil, **options)
        request(verb: :put, path: path, data: data, **options)
      end

      # Performs an HTTP request
      #
      # @param verb    [Symbol]   one of :get, :post, :delete, :put
      # @param path    [String]   the URL to send the request to
      # @param data    [#to_json] an object that can be JSONified (#keys2camel)
      # @param options [Hash]     optional arguments (with snakerized keys)
      # @option options [String] :server   (nil)     to use another server for this request
      # @option options [String] :language ('en-us') @see initialize
      # @option options [String] :token    (nil)     token received on successful connection
      # @return        [Hash] the data received from the server
      # @raise [InvalidArgumentError] when data does not respond to #to_json or
      #                               when the verb is not one of :get, :post, :delete, :put or
      #                               when the returned data is an invalid content
      # @raise [UnavailableService] when the server does not accept connections
      # @raise [KeyError] when the server does not provide an alternate list of servers when redirecting
      # @raise [WantRedirection] when the server wants the Client to change servers
      # @raise [AuthenticationError] when the provided credentials do not authenticate with the server
      # @raise [AuthorizationError] when the provided credentials are not authorized on the server
      # @raise [RequestDeniedError ] when the server denied a request from the client (permission issues)
      # @raise [NotFoundError] when the requested resource does not exist on the server
      # @raise [BadRequestError] when the request was badly formed
      # @raise [InvalidSessionIdError] when the provided {Session} was invalid
      # @raise [AuthTokenExpectedError] when no token were provided
      # @raise [RuntimeError] when the server experienced an unknown problem
      def request(verb: :get, path: '/', data: nil, **options)
        # cookies are managed automatically by the httpclient gem
        self.server = options[:server] if options[:server]
        url = "#{@uri}#{path}"
        headers = {}
        headers['Accept-Language']      = options[:language] || @language
        headers['ININ-ICWS-CSRF-Token'] = options[:token]    || @token
        @client.ssl_config.verify_mode     = OpenSSL::SSL::VERIFY_NONE # Only if turned on, we should verify by default
        @client.ssl_config.verify_callback = @client.ssl_config.method(:sample_verify_callback)
        # TODO: Timeout

        body      = nil
        object_id = nil
        if data
          object_id = data.id if data.respond_to? :id
          if verb == :get
            if data.respond_to? :keys2camel
              body = data.keys2camel(lower: true, except: [:__type])
            else
              body = data
            end
          else
            raise InvalidArgumentError, 'data does not respond to to_json' unless data.respond_to? :to_json
            headers['Content-Type'] = 'application/json'
            if data.respond_to? :keys2camel
              body = data.keys2camel(lower: true, except: [:__type]).to_json
            else
              body = data.to_json
            end
          end
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
          else raise InvalidArgumentError, 'verb'
        end
        @client.debug_dev = nil if trace.debug?
        trace.debug('HTTP') {'HTTP traffic >>>>>'}
        trace.debug('HTTP') { "Response: #{response.status} #{response.reason}" }
        if response.redirect? || HTTP::Status::SERVICE_UNAVAILABLE == response.status
          # The response was:
          # {"alternateHostList":["otherserver"],"errorId":"error.server.notAcceptingConnections","message":"This Session Manager is not currently accepting connections."}
          trace.warn('HTTP') { 'Host wants us to redirect' }
          data = JSON.parse(response.content).keys2sym
          raise HTTP::UnavailableService, data.to_json unless data[:error_id] == 'error.server.notAcceptingConnections'
          raise KeyError, 'alternate_host_list'          unless data[:alternate_host_list]
          raise HTTP::WantRedirection, data.to_json
        elsif response.ok?
          data = {}
          if response.content.size > 0
            data[:content_type] = response.header['Content-Type'].first
            content = JSON.parse(response.content)
            case content
              when Hash then data.merge! content.keys2sym
              when Array then data[:values] = content.keys2sym
              else raise InvalidArgumentError, 'content'
            end
            trace.debug('HTTP') { "Data: #{data.inspect}" }
            @token = data[:csrf_token] if data[:csrf_token]
            trace.debug('HTTP') { "Token?: #{data[:csrf_token]}, Content: #{response.content.size} Bytes of type #{data[:content_type]}"}
          end
          data[:location] = response.header['Location'].first if response.header['Location'] && !response.header['Location'].empty?
          trace.debug('HTTP') { "location?: #{data[:location]}"}
          return data
        else
          trace.error('HTTP') { "HTTP Failure: #{response.status} #{response.reason}" }
          error = { id: object_id }
          error.merge!(JSON.parse(response.content).keys2sym) if response.content.size > 0
          trace.error('HTTP') { "ICWS Failure: session=#{error[:session]}, id=#{error[:error_id]}, code=#{error[:error_code]}, message=\"#{error[:message]}\"" }
          case response.status
            when HTTP::Status::BAD_REQUEST
              # The response can be something like:
              #   {"errorId":"error.request.connection.authenticationFailure","errorCode":-2147221503,"message":"The authentication process failed."}
              raise HTTP::AuthenticationError       if error[:error_id]   == 'error.request.connection.authenticationFailure'
              raise HTTP::AuthenticationError       if error[:error_code] == -2147221503 # There was no errorId in CIC < 4.0.6
              raise HTTP::NotFoundError, error.id   if error[:error_id]   == '-2147221496'
              raise HTTP::BadRequestError, response
            when HTTP::Status::UNAUTHORIZED
              raise SessionIdExpectedError          if error[:error_code] == 1
              raise AuthTokenExpectedError          if error[:error_code] == 2
              raise HTTP::AuthorizationError, error[:error_code]
            when HTTP::Status::FORBIDDEN
              raise RequestDeniedError
            when HTTP::Status::NOT_FOUND
              raise HTTP::NotFoundError, error
            when HTTP::Status::INTERNAL
              raise RuntimeError if error[:error_code] == -2147467259
              raise RuntimeError, error
            else
              raise HTTP::HTTPError, error
          end
        end
      end
    end
  end
end
