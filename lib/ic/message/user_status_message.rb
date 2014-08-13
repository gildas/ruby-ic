require 'json'
require 'ic/message'

module Ic
  class UserStatusMessage
    include Message

    attr_reader :statuses

    def self.urn_type
      'urn:inin.com:status:userStatusMessage'
    end

    def initialize(options = {})
      super(options)
      raise MissingArgumentError, 'userStatusList' unless options[:userStatusList]
      @statuses = options[:userStatusList].collect {|item| Status.new(item)}
    end

    def self.from_json(options = {})
      # Safeguards...
      raise MissingArgumentError, '__type'         unless options[:__type]
      raise InvalidTypeError,     options[:__type] unless options[:__type] == self.urn_type
      self.new(options)
    end

    def self.subscribe(session, options = {})
      raise MissingArgumentError, 'users' unless options.include?(:user) || options.include?(:users)
      data = { userIds: [] }
      if options[:user]
        data[:userIds] << (options[:user].respond_to?(:id) ? options[:user].id : options[:user])
      elsif options[:users]
        data[:userIds] = options[:users].collect { |user| user.respond_to?(:id) ? user.id : :user }
      end
      session.http_put path: "/icws/#{session.id}/messaging/subscriptions/status/user-statuses", data: data
    end

    def self.unsubscribe(session)
      session.http_delete path: "/icws/#{session.id}/messaging/subscriptions/status/user-statuses"
      #TODO: shouldn't we use a put with a data with current user_ids minus the one we want to stop observe?
    end

    def self.update(message, &block)
      #TODO: Not sure where but we should support "delta?"
      raise InvalidArgumentError, 'message' unless message.urn_type == urn_type
      block.call(message.statuses, message.delta?) if block
    end

    def to_s
      "#{@statuses.size} Status Message#{@statuses.size > 1 ? 's' : ''}"
    end
  end
end