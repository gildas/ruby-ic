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
      options[:log_to] = options[:session].logger unless options[:log_to]
      initialize_logger(options)
      @session = options[:session]
      @id      = options[:id] || @session.user.id
      @display = options[:display] || @id
      logger.add_context(user: @id)
    end

    def status_id
      trace.debug('User') { "Requesting the current status ids" }
      info = @session.client.get path: "/icws/#{@session.id}/status/user-statuses/#{@id}", session: @session
      trace.info('User') { "Statuses: #{info}" }
      info[:session] = @session
      Status.new(info)
    end

    def to_s
      @id
    end
  end
end