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

    specify 'should have a server version' do
      session = Ic::Session.new(@config)
      expect(session).to be_truthy
      version = session.server_version
      expect(version).to_not be nil
    end

    specify 'should give a feature list' do
      session = Ic::Session.new(@config)
      expect(session).to be_truthy
      features = session.server_features
      expect(features).to be_truthy
      expect(features).to be_kind_of(Enumerable)
    end
  end
end