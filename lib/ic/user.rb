require 'json'
require 'ic/helpers'
require 'ic/exceptions'
require 'ic/logger'
require 'ic/status'
require 'ic/subscriber'

module Ic
  class User
    include Traceable
    include Subscriber
    include HTTP::Requestor

    attr_reader :id, :display
    attr_writer :display

    def initialize(**options)
      @session    = options[:session]
      self.create_logger(**options, default: @session)
      @id         = options[:id] || @session.user.id
      @display    = options[:display] || @id
      self.client = @session.client
      logger.add_context(user: @id)
    end

    def status
      trace.debug('User') { 'Requesting the current status' }
      info = http_get path: "/icws/#{@session.id}/status/user-statuses/#{@id}"
      trace.info('User') { "Status: #{info}" }
      info[:session] = @session
      Status.new(info)
    end

    def status=(options = {})
      options = { status: options } if options.kind_of?(String) || options.kind_of?(Status)
      raise MissingArgumentError, 'status' unless options[:status]
      data = {}
      if options[:status].respond_to?(:id)
        data[:statusId]      = options[:status].id
        data[:forwardNumber] = status.forward_to if status.forward_to
        data[:notes]         = status.notes      if status.notes && !status.notes.empty?
        if status.until
          data[:until]       = {
              untilDateTime: status.until,
              hasDate:       options[:has_date],
              hasTime:       options[:has_time],
          }
        end
      else
        data[:statusId]    = options[:status]
      end
      data[:forwardNumber] = options[:forward_to] if options.include?(:forward_to)
      data[:notes]         = options[:notes]      if options.include?(:notes)
      trace.debug('User') { "Setting the status to #{data[:statusId]}" }
      info = http_put path: "/icws/#{@session.id}/status/user-statuses/#{@id}", data: data
      trace.info('User') { "Status: #{info}" }
      info[:requestId]
    end

    # Subscribes to an Observable object for updates on a {Message} type.
    # @param to      [Observable] an Observable object
    # @param about   [Message]    the type of {Message}
    # @param options [Hash]       options
    # @param block   [Code]       Code to execute when the Observable notifies this
    def subscribe(to: nil, about: nil, **options, &block)
      trace.info('subscribe') { "Subscribing to Observable: #{to}"}
      #super.subscribe(to: to, about: about, **options, &block)
      @update_about = about
      @update_block = block
      to.add_observer(self)
      data = { userIds: [ @id ] }
      to.http_put path: "/icws/#{to.id}/messaging/subscriptions/status/user-statuses", data: data
    end

    # Unsubscribe from an Observable object
    # @param from [Observable] an Observable object
    def unsubscribe(from: nil)
      trace.info('subscribe') { "Unsubscribing from Observable: #{from}"}
      #super.unsubscribe(from: from)
      from.delete_observer(self)
      @update_about = @update_block = nil
      from.http_delete path: "/icws/#{from.id}/messaging/subscriptions/status/user-statuses"
      #TODO: shouldn't we use a put with a data with current user_ids minus the one we want to stop observe?
    end

    # Called by the Observable object when it changes
    # @param message [Hash] parameters given by the Observable
    def update(message: nil)
      trace.debug('subscribe') { "Received message: #{message}" }
      raise MissingArgumentError, 'message' if message.nil?
      raise InvalidArgumentError, 'message' unless message.kind_of? Message
      begin
        @update_block.call(message) if @update_block
      rescue
        trace.error('subscribe') { "While executing code block: #{@update_block}, Exception: #{$!}" }
      end
    end

    def to_s
      @id
    end
  end
end
