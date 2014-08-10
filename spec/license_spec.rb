require 'rspec'
require 'spec_helper'

describe 'License' do
  before do
    @config = load_config('spec/login.json')
    @config[:log_level] = Logger::DEBUG
  end

  specify 'should be acquired' do
    @config[:log_to] = "tmp/test-License-#{Time.now.strftime('%Y%m%d%H%M%S%L')}.log"
    session = Ic::Session.connect(@config)
    expect(session).to be_truthy
    expect(session.connected?).to be true
    begin
      licenses = session.acquire_licenses('I3_ACCESS_CLIENT')
      expect(licenses).to be_truthy
      expect(licenses.size).to be 1
      expect(licenses.first.available?).to be true
      expect(licenses.first.id).to eq 'I3_ACCESS_CLIENT'
    ensure
      session.disconnect
      expect(session.connected?).to be false
    end
  end
end