require 'ic/exceptions'
require 'ic/logger'

module Ic
  class Observer
    include Traceable

    def initialize(session, message_class)
      @session       = session
      @message_class = message_class
      self.logger    = { log_to: @session.logger }
    end

    def start(options = {}, &block)
      @block = block
      @message_class.subscribe(@session, options)
      @session.add_observer(self)
      self
    end

    def stop
      @session.delete_observer(self)
      @message_class.unsubscribe(@session)
      self
    end

    def update(message)
      begin
        @message_class.update(message, &@block)
      rescue
        trace.warn('Observer') { "#{@message_class} observer: Unsupported message type: #{message.urn_type}"}
      end
    end
  end
end
