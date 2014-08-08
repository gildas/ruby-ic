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
      results = session.acquire('I3_ACCESS_CLIENT')
      expect(results).to be_truthy
      expect(results.empty?).to be false
      #expect(results.find_index {|status| status.id == 'Available'}).to be > -1
    ensure
      session.disconnect
      expect(session.connected?).to be false
    end
  end
end