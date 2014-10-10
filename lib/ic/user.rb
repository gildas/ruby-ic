require 'json'
require 'ic/helpers'
require 'ic/exceptions'
require 'ic/logger'
require 'ic/rights_filter'
require 'ic/status'
require 'ic/subscriber'

module Ic
  # This class represents a CIC User
  # 
  # It can be used for User in Session, Queues, etc. as well as to perform administrative tasks
  # such as create a new User, Change their attributes or group membership, etc...
  class User
    include Traceable
    include Subscriber

    # @return [String] The User Identifier
    attr_reader :id

    # #return [String] The User Display name
    attr_reader :display
    attr_writer :display

    # Finds an existing User on the CIC Server
    def self.find(session: nil, id: nil, select: [], rights_filter: RightsFilter::ADMIN, actual_values: false, inherited_values: false, single_property_inherited_from: false, **options)
      raise MissingSessionError        unless session
      raise MissingArgumentError, 'id' unless id

      session.trace.info('User') { "Searching for user: #{id}" }
      data = {}
      case
        when select.respond_to?(:join)    then data[:select] = select.join(',')
        when select.kind_of?(String)      then data[:select] = select
        else raise InvalidArgumentError, 'select'
      end unless select.nil? || select.empty?
      data[:rights_filter] = rights_filter       if rights_filter != RightsFilter::ADMIN
      data[:actual_values] = actual_values       if actual_values
      data[:inherited_values] = inherited_values if inherited_values
      data[:single_property_inherited_from] = single_property_inherited_from if single_property_inherited_from

      results = session.http_get path: "/icws/#{session.id}/configuration/users/#{id}", data: data
      # Sample results: {{{2
      # {:content_type=>"application/vnd.inin.icws+JSON; charset=utf-8", :configuration_id=>{:id=>"gcadmin", :display_name=>"Administrator: Gildas Cherruel", :uri=>"/configuration/users/gcadmin"}}
      # Sample results when select='*': {{{3
      # {
      #  :content_type=>"application/vnd.inin.icws+JSON; charset=utf-8",
      #  :configuration_id=> {:id=>"gcadmin", :display_name=>"Administrator: Gildas Cherruel", :uri=>"/configuration/users/gcadmin"},
      #  :auto_answer_acd_interactions=>false, :auto_answer_non_acd_interactions=>false, :cost=>0,
      #  :created_date=>"20120228T093817Z", :last_modified_date=>"20140501T064618Z",
      #  :exclude_from_directory=>true, :fax_capability=>true, :home_site=>1, :lync_integration_enabled=>false, :lync_option=>[4],
      #  :mailbox_properties=>{:display_name=>"Administrator: Gildas Cherruel", :type=>0},
      #  :mwi_enabled=>false, :mwi_mode=>0, :nt_domain_user=>"DEMO\\gcadmin",
      #  :outlook_integration_enabled=>false, :pager_active=>false, :statistics_shift_starts=>[0],
      #  :um_destination=>"IC Server", :whisper_tone_level=>-25,
      #  :workgroups=>
      #  [
      #    {:id=>"CompanyOperator", :display_name=>"CompanyOperator", :uri=>"/configuration/workgroups/CompanyOperator"},
      #    {:id=>"RMA Finance",     :display_name=>"RMA Finance",     :uri=>"/configuration/workgroups/RMA%20Finance"},
      #    {:id=>"RMA Logistics",   :display_name=>"RMA Logistics",   :uri=>"/configuration/workgroups/RMA%20Logistics"},
      #    {:id=>"RMA Shipping",    :display_name=>"RMA Shipping",    :uri=>"/configuration/workgroups/RMA%20Shipping"}
      #  ],
      #  :status_text=>"Available",
      #  :license_properties=>
      #  {
      #    :additional_licenses=>
      #    [
      #      {:id=>"I3_ACCESS_DIALER_SUPERVISOR_PLUGIN", :display_name=>"Interaction Supervisor Plug-In: Interaction Dialer", :uri=>""},
      #      {:id=>"I3_ACCESS_HISTORICAL_REPORT_SUPERVISOR_PLUGIN", :display_name=>"Interaction Supervisor Plug-In: Historical Reporting", :uri=>""},
      #      {:id=>"I3_ACCESS_RECORDER", :display_name=>"Interaction Recorder Access", :uri=>""},
      #      {:id=>"I3_ACCESS_RECORDER_CLIENT", :display_name=>"Interaction Recorder Client Access", :uri=>""},
      #      {:id=>"I3_ACCESS_RECORDER_EXTREMEQUERY_CLIENT", :display_name=>"Interaction Recorder Extreme Query", :uri=>""},
      #      {:id=>"I3_ACCESS_RECORDER_QUALITYMONITORING", :display_name=>"Interaction Quality Manager", :uri=>""},
      #      {:id=>"I3_ACCESS_REPORT_ASSISTANT_SUPERVISOR_PLUGIN", :display_name=>"Interaction Supervisor Plug-In: Reporting Assistant", :uri=>""},
      #      {:id=>"I3_ACCESS_SYSTEM_STATUS_SUPERVISOR_PLUGIN", :display_name=>"Interaction Supervisor Plug-In: System Status", :uri=>""},
      #      {:id=>"I3_ACCESS_TRACKER", :display_name=>"Interaction Tracker Access", :uri=>""},
      #      {:id=>"I3_ACCESS_WORKGROUP_SUPERVISOR_PLUGIN", :display_name=>"Interaction Supervisor Plug-In: Workgroup", :uri=>""}
      #    ],
      #    :interaction_process_automation_type=>4,
      #    :license_active=>true,
      #    :has_client_access=>true,
      #    :media_level=>3,
      #    :allocation_type=>0
      #  },
      #  :access_control_group_assignment=>{:id=>"ACG Root", :display_name=>"Root", :uri=>""},
      #  :security_rights=>
      #  {
      #    :access_all_interaction_conferences=>{:effective_value=>true}, :access_owned_interaction_conferences=>{:effective_value=>true},
      #    :account_code_verification=>{:effective_value=>true}, :agent_preferences=>{:effective_value=>false},
      #    :allow_agent_rules=>{:effective_value=>true}, :allow_access_to_problem_reporter=>{:effective_value=>true},
      #    :allow_agent_see_own_rank=>{:effective_value=>false}, :allow_agent_see_relative_rank=>{:effective_value=>false},
      #    :allow_agent_schedule_bidding=>{:effective_value=>false}, :allow_alert_programming=>{:effective_value=>true},
      #    :allow_email_alerts=>{:effective_value=>true}, :allow_email_access_via_tui=>{:effective_value=>true},
      #    :allow_fax_access_via_tui=>{:effective_value=>true}, :allow_handler_alerts=>{:effective_value=>true},
      #    :allow_memo_alerts=>{:effective_value=>true}, :allow_mini_mode=>{:effective_value=>true},
      #    :allow_multiple_calls=>{:effective_value=>true}, :allow_related_interactions_page=>{:effective_value=>true},
      #    :allow_voice_mai_access_via_tui=>{:effective_value=>true}, :can_coach_interactions=>{:effective_value=>true},
      #    :can_create_email_attendant_profile=>{:effective_value=>true}, :can_create_inbound_attendant_profile=>{:effective_value=>true},
      #    :can_create_operator_attendant_profile=>{:effective_value=>true}, :can_create_optimizer_activity_codes=>{:effective_value=>false},
      #    :can_create_optimizer_day_classifications=>{:effective_value=>false}, :can_create_outbound_attendant_profile=>{:effective_value=>true},
      #    :can_create_questionnaire_directories=>{:effective_value=>true}, :can_create_scheduling_units=>{:effective_value=>false},
      #    :can_delete_optimizer_activity_codes=>{:effective_value=>false}, :can_delete_optimizer_day_classifications=>{:effective_value=>false},
      #    :can_delete_scheduling_units=>{:effective_value=>false}, :can_disconnect_interactions=>{:effective_value=>true},
      #    :can_initiate_secure_input=>{:effective_value=>true}, :can_join_interactions=>{:effective_value=>true},
      #    :can_modify_optimizer_activity_codes=>{:effective_value=>false}, :can_modify_optimizer_day_classifications=>{:effective_value=>false},
      #    :can_modify_optimizer_status_activity_type_mapping=>{:effective_value=>false}, :can_mute_interactions=>{:effective_value=>true},
      #    :can_override_finished_scorecards=>{:effective_value=>true}, :can_pause_interactions=>{:effective_value=>true},
      #    :can_pickup_interactions=>{:effective_value=>true}, :can_publish_process=>{:effective_value=>true},
      #    :can_put_interactions_on_hold=>{:effective_value=>true}, :can_request_assistance_from_supervisor=>{:effective_value=>true},
      #    :can_secure_recording_pause_interactions=>{:effective_value=>true}, :can_submit_time_off=>{:effective_value=>true},
      #    :can_transfer_interactions=>{:effective_value=>true}, :can_transfer_interactions_to_voicemail=>{:effective_value=>true},
      #    :can_view_optimizer_activity_codes=>{:effective_value=>false}, :can_view_optimizer_day_classifications=>{:effective_value=>false},
      #    :can_view_optimizer_status_activity_type_mapping=>{:effective_value=>false}, :can_conference_calls=>{:effective_value=>true},
      #    :debug_handlers=>{:effective_value=>true}, :use_tiff_for_faxes=>{:effective_value=>false},
      #    :have_private_contacts=>{:effective_value=>true}, :i_p_phone_provisioning_admin=>{:effective_value=>true},
      #    :add_individuals=>{:effective_value=>true}, :add_organizations=>{:effective_value=>true},
      #    :delete_individuals=>{:effective_value=>true}, :delete_organizations=>{:effective_value=>true},
      #    :modify_interactions=>{:effective_value=>true}, :modify_organizations=>{:effective_value=>true},
      #    :interaction_recorder_master_key_password_administrator=>{:effective_value=>true}, :tracker_administrator=>{:effective_value=>true},
      #    :view_other_peoples_private_interactions=>{:effective_value=>true}, :can_listen_in_on_interactions=>{:effective_value=>true},
      #    :lock_policy_sets=>{:effective_value=>false}, :login_campaign=>{:effective_value=>false},
      #    :can_manage_client_templates=>{:effective_value=>true}, :manage_handlers=>{:effective_value=>true},
      #    :mobile_office_user=>{:effective_value=>false}, :modify_configuration_change_auditing=>{:effective_value=>false},
      #    :modify_configuration_general=>{:effective_value=>false}, :modify_configuration_http_server=>{:effective_value=>false},
      #    :modify_configuration_outbound_servers=>{:effective_value=>false}, :modify_configuration_phone_number_types=>{:effective_value=>false},
      #    :modify_configuration_preview_call_behavior=>{:effective_value=>false}, :modify_individuals=>{:effective_value=>true},
      #    :can_orbit_queue=>{:effective_value=>true}, :can_park_interactions=>{:effective_value=>true},
      #    :publish_handlers=>{:effective_value=>true}, :can_user_interaction_recorder_selector=>{:effective_value=>true},
      #    :remote_control=>{:effective_value=>true}, :reporter_administrator=>{:effective_value=>true},
      #    :require_forced_authorization_code=>{:effective_value=>false}, :allow_response_management=>{:effective_value=>true},
      #    :allow_receive_voicemail=>{:effective_value=>true}, :allow_intercom_chat=>{:effective_value=>true},
      #    :allow_user_defined_telephone_number_on_remote_login=>{:effective_value=>true}, :allow_video=>{:effective_value=>true},
      #    :customize_client=>{:effective_value=>true}, :directory_admin=>{:effective_value=>true},
      #    :follow_me=>{:effective_value=>true}, :allow_persistent_connections=>{:effective_value=>true},
      #    :private_calls=>{:effective_value=>true}, :can_record_interactions=>{:effective_value=>true},
      #    :show_assistance_button=>{:effective_value=>true}, :show_coach_button=>{:effective_value=>true},
      #    :show_disconnect_button=>{:effective_value=>true}, :show_hold_button=>{:effective_value=>true},
      #    :show_join_button=>{:effective_value=>true}, :show_listen_button=>{:effective_value=>true},
      #    :allow_monitor_columns=>{:effective_value=>true}, :show_mute_button=>{:effective_value=>true},
      #    :show_park_button=>{:effective_value=>true}, :show_pause_button=>{:effective_value=>true},
      #    :show_pickup_button=>{:effective_value=>true}, :show_private_button=>{:effective_value=>true},
      #    :show_record_button=>{:effective_value=>true}, :show_secure_input_button=>{:effective_value=>true},
      #    :show_secure_recording_pause_button=>{:effective_value=>true}, :show_transfer_button=>{:effective_value=>true},
      #    :show_voicemail_button=>{:effective_value=>true}, :allow_workgroup_stats=>{:effective_value=>true},
      #    :allow_speed_dials=>{:effective_value=>true}, :allow_status_notes=>{:effective_value=>true},
      #    :trace_configuration=>{:effective_value=>true}, :outlook_tui_user=>{:effective_value=>false},
      #    :view_configuration_change_auditing=>{:effective_value=>false}, :view_configuration_general=>{:effective_value=>false},
      #    :view_configuration_http_server=>{:effective_value=>false}, :view_configuration_outbound_servers=>{:effective_value=>false},
      #    :view_configuration_phone_number_types=>{:effective_value=>false}, :view_configuration_preview_call_behavior=>{:effective_value=>false},
      #    :view_interaction_details=>{:effective_value=>true}, :view_modify_campaign_agentless_calling_type=>{:effective_value=>false},
      #    :view_modify_campaign_automatic_time_zone_mapping=>{:effective_value=>false}, :view_modify_campaign_line_settings=>{:effective_value=>false},
      #    :view_modify_campaign_max_lines=>{:effective_value=>false}, :view_modify_campaign_status=>{:effective_value=>false},
      #    :view_modify_contact_list_data_query=>{:effective_value=>false}, :view_modify_custom_handler_actions=>{:effective_value=>false},
      #    :view_modify_database_connections=>{:effective_value=>false}, :view_modify_dnc_sources=>{:effective_value=>false},
      #    :view_modify_event_log=>{:effective_value=>false}, :view_modify_time_zone_map_data=>{:effective_value=>false},
      #    :show_workgroups_profiles_tab=>{:effective_value=>true}
      #  },
      #  :access_rights=>
      #  {
      #    :list_account_codes=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :activate_others=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :activate_self=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :can_edit_access_rights=>{:effective_value=>true},
      #    :change_user_status=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :phone_number_classifications=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :client_buttons=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :coach_line_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :coach_station_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :coach_user_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :coach_workgroup_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :create_optimizer_forecasts=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :create_scheduling_unit_agent_groups=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :create_scheduling_unit_schedules=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :create_scheduling_unit_shift_rotations=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :create_scheduling_unit_shifts=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :create_scheduling_unit_timeoff_requests=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :delete_optimizer_forecasts=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :delete_scheduling_unit_agent_groups=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :delete_scheduling_unit_schedules=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :delete_scheduling_unit_shift_rotations=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :delete_scheduling_unit_shifts=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :delete_scheduling_unit_timeoff_requests=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :disconnect_line_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :disconnect_station_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :disconnect_user_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :disconnect_workgroup_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :follow_me_phone_number_classifications=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :forward_phone_number_classifications=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :hold_station_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :hold_user_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :join_line_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :join_station_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :join_user_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :join_workgroup_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :launchable_process_list=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :listen_line_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :listen_station_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :listen_user_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :listen_workgroup_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :login_station=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :manage_process_list=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :miscellaneous=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :modify_attendant_email_profiles=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :modify_attendant_inbound_profiles=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :modify_attendant_operator_profiles=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :modify_attendant_outbound_profiles=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :modify_optimizer_forecasts=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :modify_scheduling_unit_agent_groups=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :modify_scheduling_unit_configuration=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :modify_scheduling_unit_list_real_time_adherence=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :modify_scheduling_unit_schedules=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :modify_scheduling_unit_shift_rotations=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :modify_scheduling_unit_shifts=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :modify_scheduling_unit_timeoff_requests=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :mute_station_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :mute_user_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :pickup_line_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :pickup_station_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :pickup_user_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :pickup_workgroup_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :interaction_client_plugins=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :record_line_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :record_station_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :record_user_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :record_workgroup_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :response_management_documents=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :status_messages=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :transfer_line_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :transfer_station_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :transfer_user_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :transfer_workgroup_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :tui_phone_number_classifications=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_modify_optimizer_all=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_attendant_email_profiles=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_attendant_inbound_profiles=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_attendant_operator_profiles=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_attendant_outbound_profiles=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_data_source=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_feedback_surveys=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_general_directories=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_historical_reports=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_individual_statistics=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_layout_list=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_line_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_optimizer_forecasts=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_positions_list=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_process_list=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_queue_control_columns=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_recorder_questionnaires=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_report=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_scheduling_unit_agent_groups=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_scheduling_unit_configuration=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_scheduling_unit_intraday_monitoring=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_scheduling_unit_list_real_time_adherence=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_scheduling_unit_schedule_preferences=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_scheduling_unit_schedules=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_scheduling_unit_shift_rotations=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_scheduling_unit_shifts=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_scheduling_unit_timeoff_requests=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_skill_list=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_station_groups_in_search=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_station_queue_in_search=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_station_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_status_columns=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_user_interaction_history=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_user_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_workgroup=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_workgroup_queue_in_search=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_workgroup_queue=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :view_workgroup_statistics=>{:effective_value=>[{:grouping=>0, :object_type=>0}]},
      #    :e_faqs=>{:effective_value=>[{:grouping=>0, :object_type=>0}]}
      #  },
      #  :administrative_rights=>
      #  {
      #    :interaction_process_automation=>{:effective_value=>false},
      #    :attendant_defaults=>{:effective_value=>false},
      #    :interaction_feedback_configuration=>{:effective_value=>false},
      #    :client_configuration_configuration=>{:effective_value=>false},
      #    :can_publish_client_templates=>{:effective_value=>false},
      #    :collective=>{:effective_value=>false},
      #    :data_manager_configuration=>{:effective_value=>false},
      #    :default_user_configuration=>{:effective_value=>false},
      #    :interaction_dialer_configuration=>{:effective_value=>false},
      #    :dnis_mappings_configuration=>{:effective_value=>false},
      #    :fax_configuration=>{:effective_value=>false},
      #    :default_ip_phone_configuration=>{:effective_value=>false},
      #    :interaction_conference_configuration=>{:effective_value=>false},
      #    :interaction_recorder_configuration=>{:effective_value=>false},
      #    :interaction_tracker_configuration=>{:effective_value=>false},
      #    :licenses_allocation_configuration=>{:effective_value=>false},
      #    :log_retrieval_assistant_configuration=>{:effective_value=>false},
      #    :mrcp_configuration=>{:effective_value=>false},
      #    :mail_configuration=>{:effective_value=>false},
      #    :media_servers_configuration=>{:effective_value=>false},
      #    :interaction_optimizer_advanced_configuration=>{:effective_value=>false},
      #    :interaction_optimizer_agents_configuration=>{:effective_value=>false},
      #    :password_policies_configuration=>{:effective_value=>false},
      #    :peer_sites_configuration=>{:effective_value=>false},
      #    :phone_numbers_configuration=>{:effective_value=>false},
      #    :problem_reporter_configuration=>{:effective_value=>false},
      #    :default_location_configuration=>{:effective_value=>false},
      #    :sms_configuration=>{:effective_value=>false},
      #    :servers_configuration=>{:effective_value=>false},
      #    :sip_proxy_configuration=>{:effective_value=>false},
      #    :speech_recognition_configuration=>{:effective_value=>false},
      #    :default_station_configuration=>{:effective_value=>false},
      #    :system_configuration=>{:effective_value=>false},
      #    :can_edit_administrative_rights=>{:effective_value=>true},
      #    :master_administrator=>{:effective_value=>true},
      #    :sametime_configuration=>{:effective_value=>false},
      #    :session_manager_server_configuration=>{:effective_value=>false},
      #    :single_sign_on_secure_token_server=>{:effective_value=>false}
      #  },
      #  :utilizations=>
      #  {
      #    :effective_value=>
      #    [
      #      {:media_type=>6, :utilization=>100, :max_assignable=>0},
      #      {:media_type=>6, :utilization=>100, :max_assignable=>1},
      #      {:media_type=>1, :utilization=>100, :max_assignable=>1},
      #      {:media_type=>4, :utilization=>100, :max_assignable=>0},
      #      {:media_type=>4, :utilization=>100, :max_assignable=>1},
      #      {:media_type=>5, :utilization=>100, :max_assignable=>0},
      #      {:media_type=>2, :utilization=>100, :max_assignable=>0},
      #      {:media_type=>3, :utilization=>100, :max_assignable=>0}
      #    ]
      #  },
      #  :interaction_offering_timeout=>{:effective_value=>30},
      #  :password_policies=>
      #  {
      #    :effective_value=>
      #    [
      #      {:id=>"Service Account", :display_name=>"Service Account", :uri=>"/configuration/password-policies/Service%20Account"}
      #    ]
      #  },
      #  :skills=>
      #  {
      #    :effective_value=>[ {:id=>{:id=>"Language: en", :display_name=>"Language: en", :uri=>""}, :proficiency=>1, :desire_to_use=>1} ]
      #  },
      #  :client_configuration_template=>{:effective_value=>{:id=>"Default", :display_name=>"Default", :uri=>""}}
      # }
      # 3}}}
      # 2}}}
      options.merge!(results[:configuration_id])
      self.new(session: session, **options)
    end

    # Creates a new User on the CIC Server
    def self.create(session: nil, id: nil, display_name: nil, **options)
      raise MissingSessionError        unless session
      raise MissingArgumentError, 'id' unless id
      configuration_id = { id: id }
      configuration_id[:display_name] = display_name unless display_name.nil?
      data = { configuration_id: configuration_id }.merge(options)
      session.http_post path: "/icws/#{session.id}/configuration/users", data: data
    end

    # Initializes a new User instance
    #
    # This does not create new users in CIC! Use {User.create} for that
    #
    # @param session      [Session] The Session used by this object.
    # @param id           [String]  The User Identifier
    # @param display_name [String]  The USer Display name
    # @param options      [Hash]    Extra options
    # @see Ic::HTTP::Client for HTTP specific options
    # @see Ic::Logger       for Logger specific options
    def initialize(session: nil, id: nil, display_name: nil, **options)
      @session  = session
      @id       = id || options[:user_id]
      @display  = display_name || options[:user_display_name] || @id
      @location = options[:uri]
      self.create_logger(**options, default: @session)
      logger.add_context(user: @id)
    end

    # Queries the CIC Server for the User's Status
    #
    # @return [Status] the retrieved Status
    # @raise [MissingSessionError] when the session is missing
    def status
      raise MissingSessionError unless @session
      trace.debug('User') { 'Requesting the current status' }
      info = @session.http_get path: "/icws/#{@session.id}/status/user-statuses/#{@id}"
      trace.info('User') { "Status: #{info}" }
      info[:session] = @session
      Status.new(info.merge(user: self))
    end

    # Sets the User's Status on the CIC Server
    #
    # @param options [Hash] Status parameters
    # @raise [MissingSessionError] when the session is missing
    # @raise [MissingArgumentError] when the status is missing
    def status=(options = {})
      options = { status: options } if options.kind_of?(String) || options.kind_of?(Status)
      raise MissingArgumentError, 'status' unless options[:status]
      raise MissingSessionError unless @session
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
      info = @session.http_put path: "/icws/#{@session.id}/status/user-statuses/#{@id}", data: data
      trace.info('User') { "Status: #{info}" }
      info[:requestId]
    end

    # String representation of a User
    #
    # @return [String] String representation
    def to_s
      @id
    end
  end
end
