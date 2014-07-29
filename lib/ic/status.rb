require 'json'
require 'ic/helpers'
require 'ic/http'
require 'ic/exceptions'
require 'ic/logger'

module Ic
  class Status
    include Traceable

    attr_reader :id, :message, :group_tag, :icon_uri, :system_id

    def self.find_all(session, options = {})
      session.logger.debug("Status") { "Requesting the list of statuses on session #{session}" }
      info = session.client.get path: "/icws/#{session.id}/status/status-messages", session: self
      session.logger.info("Session##{@id}") { "Statuses: #{info}" }
      info[:statusMessageList].collect { |item| Status.new(item) }
    end

    def initialize(options = {})
      initialize_logger(options)
      @session         = options[:session]
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
    end


    def can_have_date? ; @can_have_date end

    def can_have_time? ; @can_have_time end

    def acd? ; @acd end

    def after_call_work? ; @after_call_work end

    def do_not_disturb? ; @do_not_disturb end

    def forward? ; @forward end

    def persistent? ; @persistent end

    def selectable? ; @selectable end

    def to_s
      message
    end
  end
end
