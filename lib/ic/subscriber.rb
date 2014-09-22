require 'ic/exceptions'

module Ic
  # This interface is used to subscribe (observe) an Observable object (e.g.:#{Session})
  module Subscriber

    # Subscribes to an {Observable} object for updates on a {Message} type.
    # @param to      [Observable] an {Observable} object
    # @param about   [Message]    the type of {Message}
    # @param options [Hash]       options
    # @param block   [Code]       Code to execute when the {Observable} notifies this
    def subscribe(to: nil, about: nil, **options, &block)
      raise MissingArgumentError, 'to'    if to.nil?
      raise InvalidTypeError,     'to'    unless to.kind_of? Observable
      raise MissingArgumentError, 'about' if about.nil?
      raise InvalidTypeError,     'about' unless about.kind_of? Message
      @update_about = about
      @update_block = block
      to.add_observer(self)
      self
    end

    # Unsubscribe from an {Observable} object
    # @param from [Observable] an {Observable} object
    def unsubscribe(from: nil)
      raise MissingArgumentError, 'from' if from.nil?
      raise InvalidTypeError,     'from' unless from.kind_of? Observable
      from.delete_observer(self)
      @update_about = @update_block = nil
      self
    end

    # Called by the {Observable} object when it changes
    # @param options [Hash] parameters given by the Observable
    def update(**options)
      @update_block.call(**options) if @update_block
    end
  end
end
