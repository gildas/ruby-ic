module Ic
  # This class represents country information
  #
  # @see http://www.iso.org/iso/country_codes.htm Country codes (ISO 3166)
  class Country
    # return [String] The country identifier
    attr_reader :id

    # return [String] The country name
    attr_reader :name

    # Initializes a new Country
    # @overload initialize(id,name)
    #   @param id          [String] The country identifier (ISO 3166)
    #   @param name        [String] A human readable name (e.g.: 'France')
    #   @param displayName [String] A synonym for parameter name
    def initialize(id:, name: nil, displayName: nil)
      @id   = id
      @name = name || displayName || @id # IC API key: displayName
    end
  end
end
