require 'rspec'
require 'spec_helper'

describe 'Session' do
  context 'valid server and credentials' do
    before do
      @config = load_config('spec/login.json')
      @config[:log_to]    = "tmp/test-session#{Time.now.strftime('%Y%m%d%H%M%S%L')}.log"
      @config[:log_level] = Logger::DEBUG
    end

    specify 'should connect and disconnect' do
      session = Ic::Session.connect(@config)
      expect(session).to be_truthy
      expect(session.connected?).to be true
      session.disconnect
      expect(session.connected?).to be false
    end

    specify 'should get a version from the CIC server' do
      session = Ic::Session.new(@config)
      expect(session).to be_truthy
      version = session.version
      expect(version).to_not be nil
    end

    specify 'should get a feature list from the CIC server' do
      session = Ic::Session.new(@config)
      expect(session).to be_truthy
      features = session.features
      expect(features).to be_truthy
      expect(features).to be_kind_of(Enumerable)
    end
  end
end