require 'time'
require 'json'
require 'ic/helpers'
require 'ic/exceptions'
require 'ic/logger'

module Ic
  class Status
    include Traceable

    attr_reader :id, :message, :group_tag, :icon_uri, :system_id, :changed_at, :on_phone_at, :notes
    attr_reader :forward_to, :until, :stations, :servers, :user_id

    def self.find_all(session, options = {})
      session.trace.debug('Status') { "Requesting list of statuses, options=#{options}" }
      info = session.http_get path: "/icws/#{session.id}/status/status-messages"
      session.trace.info('Status') { "Statuses: #{info}" }
      info[:statusMessageList].collect { |item| Status.new(item.merge(session: session)) }
    end

    def self.find_all_ids(session, options = {})
      if options[:user]
        session.trace.debug('Status') { "Requesting the list of status ids for user #{options[:user]}" }
        user_id = options[:user].respond_to?(:id) ? options[:user].id : options[:user]
        info = session.http_get path: "/icws/#{session.id}/status/status-messages-user-access/#{user_id}"
        session.trace.info('Status') { "Statuses: #{info}" }
        info[:statusMessages]
      else
        session.trace.debug('Status') { "Requesting list of status ids, options=#{options}" }
        info = session.http_get path: "/icws/#{session.id}/status/status-messages"
        session.trace.info('Status') { "Statuses: #{info}" }
        info[:statusMessageList].collect { |item| item[:statusId] }
      end
    end

    def initialize(options = {})
      self.logger      = options
      @can_have_date   = options.include?(:canHaveDate) ? options[:canHaveDate] : false
      @can_have_time   = options.include?(:canHaveTime) ? options[:canHaveTime] : false
      @group_tag       = options[:groupTag]
      @acd             = options.include?(:isAcdStatus) ? options[:isAcdStatus] : false
      @after_call_work = options.include?(:isAfterCallWorkStatus) ? options[:isAfterCallWorkStatus] : false
      @allow_follow_up = options.include?(:isAllowFollowUpStatus) ? options[:isAllowFollowUpStatus] : false
      @do_not_disturb  = options.include?(:isDoNotDisturbStatus) ? options[:isDoNotDisturbStatus] : false
      @forward         = options.include?(:isForwardStatus) ? options[:isForwardStatus] : false
      @persistent      = options.include?(:isPersistentStatus) ? options[:isPersistentStatus] : false
      @selectable      = options.include?(:isSelectableStatus) ? options[:isSelectableStatus] : false
      @id              = options[:statusId]
      @system_id       = options[:systemId]
      @icon_uri        = options[:iconUri]
      @message         = options[:messageText]
      @changed_at      = DateTime.parse(options[:statusChanged]) if options.include?(:statusChanged)
      @logged_in       = options.include?(:loggedIn) ? options[:loggedIn] : false
      @on_phone        = options.include?(:onPhone) ? options[:onPhone] : false
      @on_phone_at     = DateTime.parse(options[:onPhoneChanged]) if options.include?(:onPhoneChanged)
      @notes           = options[:notes] || ''
      @forward_to      = options[:forwardNumber]
      @until           = DateTime.parse(options[:until]) if options.include?(:until)
      @stations        = options[:stations] || []
      @servers         = options[:icServers] || []
      @user_id         = options[:user_id] || options[:userId]
    end

    def can_have_date? ; @can_have_date end

    def can_have_time? ; @can_have_time end

    def acd? ; @acd end

    def after_call_work? ; @after_call_work end

    def do_not_disturb? ; @do_not_disturb end

    def forward? ; @forward end

    def persistent? ; @persistent end

    def selectable? ; @selectable end

    def logged_in? ; @logged_in end

    def on_phone? ; @on_phone end

    def to_s
      message || id
    end

    class Observer
      def initialize(options = {}, &block)
        #TODO: We should also support Status properties to limit
        raise MissingArgumentError, 'session' unless (@session = options[:session])
        @user_ids = []
        if options[:user]
          @user_ids = [ options[:user].respond_to?(:id) ? options[:user].id : options[:user] ]
        elsif options[:users]
          @user_ids = options[:users].collect { |user| user.respond_to?(:id) ? user.id : :user }
        else
          raise MissingArgumentError, 'user or users'
        end
        @block = block
      end

      def self.start(options = {}, &block)
        observer = Observer.new(options, &block)
        observer.start
        observer
      end

      def start
        data = {
            userIds: @user_ids
        }
        @session.http_put path: "/icws/#{@session.id}/messaging/subscriptions/status/user-statuses", data: data
        @session.add_observer(self)
      end

      def stop
        @session.delete_observer(self)
        @session.http_delete path: "/icws/#{@session.id}/messaging/subscriptions/status/user-statuses"
        #TODO: shouldn't we use a put with a data with current user_ids minus the one we want to stop observe?
      end

      def update(message)
        #TODO: Not sure where but we should support "delta?"
        @block.call(message) if @block
      end
    end
  end
end
