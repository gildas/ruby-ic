require 'json'
require 'ic/helpers'
require 'ic/http'
require 'ic/exceptions'
require 'ic/logger'

module Ic
  class Status
    include Traceable

    def initialize(options = {})
      initialize_logger(options)
    end

    def self.find_all(session, options = {})
      session.logger.debug("Status") { "Requesting the list of statuses on session #{session}" }
      info = session.client.get path: "/icws/#{session.id}/status/status-messages", session: self
      session.logger.info("Session##{@id}") { "Statuses: #{info}" }
      info[:statusMessageList]
    end

  end
end
