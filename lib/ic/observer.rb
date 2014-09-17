require 'ic/exceptions'
require 'ic/logger'

module Ic
  class Observer
    include Traceable

    def initialize(session: nil, message_class: nil)
      raise MissingArgumentError, 'session'       if session.nil?
      raise MissingArgumentError, 'message_class' if message_class.nil?
      @session       = session
      @message_class = message_class
      self.logger    = @session.logger
    end

    def start(**options, &block)
      @block = block
      @message_class.subscribe(session: @session, **options)
      @session.add_observer(self)
      self
    end

    def stop
      @session.delete_observer(self)
      @message_class.unsubscribe(session: @session)
      self
    end

    def update(message: nil)
      raise MissingArgumentError, 'message' if message.nil?
      begin
        @message_class.update(message: message, &@block)
      rescue InvalidArgumentError
        trace.warn('Observer') { "#{@message_class} observer: Unsupported message type: #{message.urn_type}"}
      end
    end
  end
end
