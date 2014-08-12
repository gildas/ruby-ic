require 'rspec'

describe 'Status' do
  before do
    @config = load_config('spec/login.json')
    @config[:log_level] = Logger::DEBUG
  end

  specify 'should have a list' do
    @config[:log_to] = "tmp/test-Status-#{Time.now.strftime('%Y%m%d%H%M%S%L')}.log"
    session = Ic::Session.connect(@config)
    expect(session).to be_truthy
    expect(session.connected?).to be true
    begin
      statuses = Ic::Status.find_all(session)
      expect(statuses).to be_truthy
      expect(statuses.empty?).to be false
      expect(statuses.find_index {|status| status.id == 'Available'}).to be > -1
    ensure
      session.disconnect
      expect(session.connected?).to be false
    end
  end

  specify 'should have a list in French' do
    @config[:log_to] = "tmp/test-Status(FR)-#{Time.now.strftime('%Y%m%d%H%M%S%L')}.log"
    @config[:language] = 'fr-fr'
    session = Ic::Session.connect(@config)
    expect(session).to be_truthy
    expect(session.connected?).to be true
    begin
      statuses = Ic::Status.find_all(session)
      expect(statuses).to be_truthy
      expect(statuses.empty?).to be false
      expect(statuses.find_index {|status| status.id == 'Available'}).to be > -1
    ensure
      session.disconnect
      expect(session.connected?).to be false
    end
  end

  specify 'should have a list for logged in user' do
    @config[:log_to] = "tmp/test-StatusIdsForLoggedInUser-#{Time.now.strftime('%Y%m%d%H%M%S%L')}.log"
    session = Ic::Session.connect(@config)
    expect(session).to be_truthy
    expect(session.connected?).to be true
    begin
      statuses = Ic::Status.find_all_ids(session, user: session.user)
      expect(statuses).to be_truthy
      expect(statuses.empty?).to be false
      expect(statuses.find_index {|status_id| status_id == 'Available'}).to be > -1
    ensure
      session.disconnect
      expect(session.connected?).to be false
    end
  end

  specify 'should get the status of the logged in user' do
    @config[:log_to] = "tmp/test-User-Status-#{Time.now.strftime('%Y%m%d%H%M%S%L')}.log"
    session = Ic::Session.connect(@config)
    expect(session).to be_truthy
    expect(session.connected?).to be true
    begin
      status = session.user.status
      expect(status).to be_truthy
      expect(status.id).to be_instance_of String
    ensure
      session.disconnect
      expect(session.connected?).to be false
    end
  end

  specify 'should set the status of the logged in user' do
    @config[:log_to] = "tmp/test-User-Status=-#{Time.now.strftime('%Y%m%d%H%M%S%L')}.log"
    session = Ic::Session.connect(@config)
    expect(session).to be_truthy
    expect(session.connected?).to be true
    begin
      current_status = session.user.status
      expect(current_status).to be_truthy
      expect(current_status.id).to be_instance_of String
      session.user.status = 'Do Not disturb'
      new_status = session.user.status
      expect(new_status).to be_truthy
      expect(new_status.id).to eq 'Do Not disturb'
      session.user.status = current_status
      new_status = session.user.status
      expect(new_status).to be_truthy
      expect(new_status.id).to eq current_status.id
    ensure
      session.disconnect
      expect(session.connected?).to be false
    end
  end
end
