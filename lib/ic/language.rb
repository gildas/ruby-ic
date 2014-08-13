require 'ic/logger'
require 'ic/country'

module Ic
  class Language
    attr_reader :id, :name, :countries

    def self.find_all(session, options = {})
      session.trace.debug('Language') { "Requesting list of languages, options=#{options}" }
      info = session.http_get path: "/icws/#{session.id}/configuration/system/languages"
      session.trace.info('Language') { "Languages: #{info}" }
      info[:languages].collect { |item| Language.new(item.merge(session: session)) }
    end

    def initialize(options = {})
      @id        = options[:language][:id]
      @name      = options[:language][:displayName]
      @countries = options[:countries].collect {|country_info| Country.new(country_info)} if options[:countries] && !options[:countries].empty?
    end

    def to_s
      "#{@id} (#{@name})"
    end
  end
end