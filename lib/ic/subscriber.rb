require 'ic/exceptions'

module Ic
  # This interface is used to subscribe (observe) an Observable object (e.g.:#{Session})
  module Subscriber

    # Subscribes to a {Message} on the current {Session}
    #
    # The Class must have an instance variable named @session ({Session}).
    #
    # @param to      [Class] the type of {Message}
    # @param block   [Code]  Code to execute when the Observable notifies this
    # @raise [MissingArgumentError] when 'to' is missing
    # @raise [InvalidTypeError]     when 'to' cannot #subscribe
    # @raise [MissingSessionError]  when the session is missing
    def subscribe(to: nil, &block)
      raise MissingArgumentError, 'to'      if     to.nil?
      raise InvalidTypeError,     'to'      unless to.respond_to? :subscribe
      raise MissingSessionError             unless session = self.instance_variable_get(:@session)
      raise InvalidTypeError,     'session' unless session.kind_of? Session

      self.trace.info('subscribe') { "Subscribing #{self.class} #{self} to #{to} on session #{@session}"} if self.respond_to? :trace
      @update_about = to
      @update_block = block
      session.add_observer(self)
      to.subscribe(session: session, data: self)
      self
    end

    # Unsubscribe from a {Message} on the current {Session}.
    #
    # The Class must have an instance variable named @session ({Session}).
    #
    # @param from [Class] the type of {Message}
    # @raise [MissingArgumentError] when 'from' is missing
    # @raise [InvalidTypeError]     when 'from' cannot #unsubscribe
    # @raise [MissingSessionError]  when the session is missing
    def unsubscribe(from: nil)
      raise MissingArgumentError, 'from'    if from.nil?
      raise InvalidTypeError,     'from'    unless from.respond_to? :unsubscribe
      raise MissingSessionError             unless session = self.instance_variable_get(:@session)
      raise InvalidTypeError,     'session' unless session.kind_of? Session
      self.trace.info('subscribe') { "Unsubscribing #{self.class} #{self} from #{from} on session #{session}"} if self.respond_to? :trace
      session.delete_observer(self)
      @update_about = @update_block = nil
      from.unsubscribe(session: session, data: self)
      self
    end

    # Called by the Observable object when it changes
    #
    # @param data [Object] Data given by the Observable object
    def update(data)
      self.trace.info('subscribe')  { "Received update!"     } if self.respond_to? :trace
      self.trace.debug('subscribe') { "update data: #{data}" } if self.respond_to? :trace
      begin
        @update_block.call(data) if @update_block
      rescue
        self.trace.error('subscribe') { "While executing code block: #{@update_block}, Exception: #{$!}" } if self.respond_to? :trace
      end
    end
  end
end
