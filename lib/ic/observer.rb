require 'ic/exceptions'
require 'ic/logger'

module Ic
  class Observer
    include Traceable

    def initialize(session, message_class)
      raise InvalidArgumentError, 'session'       if session.nil?
      raise InvalidArgumentError, 'message_class' if message_class.nil?

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
    end

    def update(message)
      #TODO: Not sure where but we should support "delta?"
      if message.urn_type == @message_class.urn_type
        @block.call(message.statuses, message.delta?) if @block
      else
        trace.warn('Observer') { "UserStatusMessage observer: Unsupported message type: #{message.urn_type}"}
      end
    end
  end
end
