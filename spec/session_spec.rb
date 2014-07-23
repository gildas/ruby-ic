require 'rspec'
require 'spec_helper'

describe 'Session' do
  context 'valid server and credentials' do
    before do
      @config = load_config('spec/login.json')
      #@config[:debug] = true
    end

    it 'should connect and disconnect' do
      session = Ic::Session.connect(@config)
      expect(session).to be_truthy
      expect(session.connected?).to be true
      session.disconnect
      expect(session.connected?).to be false
    end

    it 'should have a server version' do
      session = Ic::Session.new(@config)
      expect(session).to be_truthy
      version = session.server_version
      expect(version).to_not be nil
    end
  end
end