require 'rspec'
require 'spec_helper'

describe 'Session' do
  context 'valid server and credentials' do
    before do
      @config = load_config('spec/login.json')
    end

    it 'should connect' do
      session = Ic::Session.connect(@config)
      session.should be
      session.connected?.should be_true
    end
  end
end