module Ic
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

    def self.from_hash(options = {})
      return [ DEFAULT ] unless options.include? :media_types
      options2types = lambda do |object|
        case object
          when Array  then object.collect {|item| options2types[item]}.flatten
          when Fixnum then [ object ]
          when String then [ self.from_string(object) ]
          else raise ArgumentError, "Unsupported Media Type: #{object}"
        end
      end
      options2types[options[:media_types]]
    end

    def self.from_string(string)
      return ALL     if string =~ /^(all)$/i
      return DEFAULT if string =~ /^(default)$/i
      media_type = %w{ NONE CALL CHAT EMAIL GENERIC CALLBACK SMS WORKITEM }.find_index { |type| string =~ /^(#{type})/i }
      raise ArgumentError, "Unsupported Media Type: \"#{string}\"" if media_type.nil?
      media_type
    end
  end
end