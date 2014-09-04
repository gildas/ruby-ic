require 'ic/logger'
require 'ic/country'

module Ic
  # Represents a Language on a CIC Server.
  #
  # @see http://www.iso.org/iso/home/standards/language_codes.htm Language codes (ISO 639-1)
  # @see http://www.iso.org/iso/country_codes.htm Country codes (ISO 3166)
  class Language
    # @return [String] the ISO 639-1 and ISO 3166 identifier of the Language.
    # @example 'en-us'
    # @example 'fr-fr'
    attr_reader :id

    # @return [String] the human name of the language (in English)
    attr_reader :name

    # A list of all countries supported by the CIC server when available
    attr_reader :countries

    # Requests a list of all languages supported by the CIC server
    # @param session [Session, String] The {Session} to query or its identifier (as a string)
    # @param options [Hash]            Additional options for the HTTP {Client}
    # @returns {Array<Language>]       The list of all supported languages
    def self.find_all(session: session, **options)
      session.trace.debug('Language') { "Requesting list of languages, options=#{options}" }
      info = session.http_get path: "/icws/#{session.id}/configuration/system/languages"
      session.trace.info('Language') { "Languages: #{info}" }
      info[:languages].collect { |item| Language.new(item.merge(session: session)) }
    end

    # Initializes a {Language}
    # @param options [Hash] Describes the language
    def initialize(options = {})
      @id        = options[:language][:id]
      @name      = options[:language][:displayName]
      @countries = options[:countries].collect {|country_info| Country.new(country_info)} if options[:countries] && !options[:countries].empty?
    end

    # Returns a string form of the Language
    def to_s
      "#{@id} (#{@name})"
    end
  end
end
