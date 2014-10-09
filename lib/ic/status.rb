require 'time'
require 'json'
require 'ic/helpers'
require 'ic/exceptions'
require 'ic/logger'

module Ic
  # This class is used to manipulate User Statuses
  class Status
    include Traceable

    # @return [String] The Status Identifier
    attr_reader :id

    # @return [String] The localized Status Message
    attr_reader :message

    # @return [String] The Group Tag
    attr_reader :group_tag

    # @return [String] The URI of the icon describing the status
    attr_reader :icon_uri

    # @return [String] The System Identifier
    attr_reader :system_id

    # @return [Datetime] When the Status was last set
    attr_reader :changed_at

    # @return [Datetime] When the current interaction started if the Status is flagged On The Phone
    attr_reader :on_phone_at

    # @return [String] Notes
    attr_reader :notes

    # @return [String] Which number to forward the interaction if the Status is flagged Forward
    attr_reader :forward_to

    # @return [DateTime] The Date until the Status is valid
    attr_reader :until

    # @return [String] The Stations impacted by this Status
    attr_reader :stations

    # @return [String] The CIC servers where this Status is valid
    attr_reader :servers

    # @return [User] The CIC User concerned by this Status
    attr_reader :user

    # Collects all Status Messages from a CIC server
    #
    # @param session [Session] The {Session} to use
    # @param options [Hash]    Extra options
    # @return [Array<Status>]  list of retrieved statuses
    def self.find_all(session: nil, **options)
      raise MissingArgumentError, 'session' if session.nil?
      session.trace.debug('Status') { "Requesting list of statuses, options=#{options}" }
      info = session.http_get path: "/icws/#{session.id}/status/status-messages"
      session.trace.info('Status') { "Statuses: #{info}" }
      info[:status_message_list].collect { |item| Status.new(item.merge(session: session)) }
    end

    # Collects all Status Messages Identifier from a CIC server
    #
    # If :user is given, retrieves only ids for that user
    #
    # @param session [Session] The {Session} to use
    # @param options [Hash]    Extra options
    # @option options [String] user (nil) The user filter
    # @return [Array<Status>]  list of retrieved statuses
    def self.find_all_ids(session: nil, user: nil, **options)
      raise MissingArgumentError, 'session' if session.nil?
      if !user.nil?
        session.trace.debug('Status') { "Requesting the list of status ids for user #{options[:user]}" }
        user_id = user.respond_to?(:id) ? user.id : user
        info = session.http_get path: "/icws/#{session.id}/status/status-messages-user-access/#{user_id}"
        session.trace.info('Status') { "Statuses: #{info}" }
        info[:status_messages]
      else
        session.trace.debug('Status') { "Requesting list of status ids, options=#{options}" }
        info = session.http_get path: "/icws/#{session.id}/status/status-messages"
        session.trace.info('Status') { "Statuses: #{info}" }
        info[:status_message_list].collect { |item| item[:statusId] }
      end
    end

    # Initializes a Status message.
    #
    # @param options [Hash] 
    def initialize(**options)
      self.create_logger(**options)
      @can_have_date   = options.include?(:can_have_date) ? options[:can_have_date] : false
      @can_have_time   = options.include?(:can_have_time) ? options[:can_have_time] : false
      @group_tag       = options[:group_tag]
      @acd             = options.include?(:is_acd_status) ? options[:is_acd_status] : false
      @after_call_work = options.include?(:is_after_call_work_status) ? options[:is_after_call_work_status] : false
      @allow_follow_up = options.include?(:is_allow_follow_up_status) ? options[:is_allow_follow_up_status] : false
      @do_not_disturb  = options.include?(:is_do_not_disturb_status) ? options[:is_do_not_disturb_status] : false
      @forward         = options.include?(:is_forward_status) ? options[:is_forward_status] : false
      @persistent      = options.include?(:is_persistent_status) ? options[:is_persistent_status] : false
      @selectable      = options.include?(:is_selectable_status) ? options[:is_selectable_status] : false
      @id              = options[:status_id]
      @system_id       = options[:system_id]
      @icon_uri        = options[:icon_uri]
      @message         = options[:message_text]
      @changed_at      = DateTime.parse(options[:status_changed]) if options.include?(:status_changed)
      @logged_in       = options.include?(:logged_in) ? options[:logged_in] : false
      @on_phone        = options.include?(:on_phone) ? options[:on_phone] : false
      @on_phone_at     = DateTime.parse(options[:on_phone_changed]) if options.include?(:on_phone_changed)
      @notes           = options[:notes] || ''
      @forward_to      = options[:forward_number]
      @until           = DateTime.parse(options[:until]) if options.include?(:until)
      @stations        = options[:stations] || []
      @servers         = options[:ic_servers] || []
      @session         = options[:session]
      if (options[:user])
        @user      = options[:user]
        @session ||= @user.session  # Get the Session from the User if we don't have it
      elsif options[:user_id]
        @user = User.new(id: options[:user_id], session: @session, **options)
      elsif !@session.nil? && @session.respond_to?(:user)
        @user = @session.user
      end
      trace.debug('status') { "Status: #{@id} for user: #{@user}" }
    end

    # @return [Boolean] True if the Status can contain a date
    def can_have_date? ; @can_have_date end

    # @return [Boolean] True if the Status can contain a time
    def can_have_time? ; @can_have_time end

    # @return [Boolean] True if the Status is in an ACD context
    def acd? ; @acd end

    # @return [Boolean] True if the Status is flagged After Call Work
    def after_call_work? ; @after_call_work end

    # @return [Boolean] True if the Status is flagged Do Not Disturb
    def do_not_disturb? ; @do_not_disturb end

    # @return [Boolean] True if the Status is flagged Forward
    def do_not_disturb? ; @do_not_disturb end
    def forward? ; @forward end

    # @return [Boolean] True if the Status is persistent
    def persistent? ; @persistent end

    # @return [Boolean] True if the Status is selectable by the agent/user
    def selectable? ; @selectable end

    # @return [Boolean] True if the agent/user is logged in
    def logged_in? ; @logged_in end

    # @return [Boolean] True if the agent/user is on the phone
    def on_phone? ; @on_phone end

    # String representation of a Session
    #
    # Shows the message or the identifier of the Status
    #
    # @return [String] String representation
    def to_s
      "#{message || id} for #{user}"
    end
  end
end
