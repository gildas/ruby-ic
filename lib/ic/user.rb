require 'json'
require 'ic/helpers'
require 'ic/exceptions'
require 'ic/logger'
require 'ic/status'

module Ic
  class User
    include Traceable

    attr_reader :id, :display
    attr_writer :display

    def initialize(options = {})
      initialize_logger(options)
      @session = options[:session]
      @id      = options[:id] || @session.user.id
      @display = options[:display] || @id
    end

    def status_id
      @logger.debug('User') { "Requesting the current status ids for user #{options[:user]}" }
      info = @session.client.get path: "/icws/#{@session.id}/status/user-statuses/#{@id}", session: @session
      @logger.info('User') { "Statuses: #{info}" }
      #TODO: What do we do with the info[:notes] if present
      Status.new(info)
    end

    def to_s
      @id
    end
  end
end