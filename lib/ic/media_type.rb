module Ic
  # This module describes the various media types a {Session} can claim to process
  module MediaType
    NONE     = 0
    CALL     = 1
    CHAT     = 2
    EMAIL    = 3
    GENERIC  = 4
    CALLBACK = 5
    SMS      = 6
    WORKITEM = 7

    ALL      = [ CALL, CHAT, EMAIL, GENERIC, CALLBACK, SMS, WORKITEM ]
    DEFAULT  = CALL

    # Creates MediaType information from a Hash (typically from JSON)
    # @param [Array, String, Fixnum]  media_types ([]) contains media type(s)
    # @param [Hash]                   options contains other options we can ignore
    # @return [Array<Fixnum>, Fixnum] The medika type(s) using constants
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
    # @param  [string] string The name of the MediaType
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
