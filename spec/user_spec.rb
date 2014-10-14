require 'rspec'
require 'spec_helper'

describe Ic::User do
  before(:context) do
    @logger  = Ic::Logger.create(log_to: "tmp/test-#{described_class}.log", log_mode: 'w', log_level: Logger::DEBUG)
    @logger.info('Group') { @logger.banner(described_class.to_s) }
    @session = Ic::Session.connect(from: 'spec/login.json', log_to: @logger)
    expect(@session).to be_truthy
    expect(@session.connected?).to be true
  end

  after(:context) do
    if (@session)
      @session.disconnect
      expect(@session.connected?).to be false
    end
    @logger.close
  end

  context('User Queries') do
    specify 'should get the configuration of logged in user' do |example|
      @logger.info('Example') { @logger.banner(example.description) }
      user = Ic::User.find(session: @session, id: @session.user.id, rights_filter: Ic::RightsFilter::LOGGEDINUSER)
      expect(user).to be_truthy
      expect(user.id).to eq @session.user.id
    end

    specify 'should get extra configuration of logged in user' do |example|
      @logger.info('Example') { @logger.banner(example.description) }
      user = Ic::User.find(session: @session, id: @session.user.id, select: ['homeSite'], rights_filter: Ic::RightsFilter::LOGGEDINUSER)
      expect(user).to be_truthy
      expect(user.id).to eq @session.user.id
    end

    specify 'should not be able to create a user' do |example|
      @logger.info('Example') { @logger.banner(example.description) }
      expect { Ic::User.create(session: @session, id: 'tempuser', display_name: 'Temp User', extension: '99999') }.to raise_error(Ic::HTTP::RequestDeniedError)
    end
  end
end
