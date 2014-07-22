require 'rspec'
require 'spec_helper'

describe 'Session' do
  context 'valid server and credentials' do
    before do
      @config = load_config('spec/login.json')
    end

    it 'should connect' do
      session = Ic::Session.connect(@config)
      expect(session).to be_truthy
      expect(session.connected?).to be true
    end
  end
end