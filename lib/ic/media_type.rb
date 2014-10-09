module Ic
  # This module describes the various media types a {Session} can claim to process
  module MediaType
    # No media is allowed
    NONE     = 0
    # Calls are allowed
    CALL     = 1
    # Web chats are allowed
    CHAT     = 2
    # Emails are allowed
    EMAIL    = 3
    # Generic Objects are allowed
    GENERIC  = 4
    # Callbacks are allowed
    CALLBACK = 5
    # SMS messages are allowed
    SMS      = 6
    # Work Items from Interaction Process Automation are allowed
    WORKITEM = 7

    # All media are allowed
    ALL      = [ CALL, CHAT, EMAIL, GENERIC, CALLBACK, SMS, WORKITEM ]

    # By default, calls only are allowed
    DEFAULT  = CALL

    # Creates MediaType information from a Hash (typically from JSON)
    # @param media_types [Array, String, Fixnum]  ([]) contains media type(s)
    # @param options     [Hash]                   contains other options we can ignore
    # @return [Array<Fixnum>, Fixnum] The media type(s) using constants
    def self.from_hash(media_types: [], **options)
      return [ DEFAULT ] if media_types.nil? || media_types.empty?
      options2types = lambda do |object|
        case object
          when Array  then object.collect {|item| options2types[item]}.flatten
          when Fixnum then [ object ]
          when String then [ self.from_string(object) ]
          else raise ArgumentError, "Unsupported Media Type: #{object}"
        end
      end
      options2types[media_types]
    end

    # Creates a MediaType constant from its string representaion
    # @param string [string] The name of the MediaType
    # @return [Fixnum] The MediaType identifier
    def self.from_string(string)
      return ALL     if string =~ /^(all)$/i
      return DEFAULT if string =~ /^(default)$/i
      media_type = %w{ NONE CALL CHAT EMAIL GENERIC CALLBACK SMS WORKITEM }.find_index { |type| string =~ /^(#{type})/i }
      raise ArgumentError, "Unsupported Media Type: \"#{string}\"" if media_type.nil?
      media_type
    end
  end
end
