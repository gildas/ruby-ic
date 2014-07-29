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
    ensure
      session.disconnect
      expect(session.connected?).to be false
    end
  end
end