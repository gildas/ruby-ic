require 'rspec'
require 'spec_helper'

describe Ic::User do
  before(:context) do
    @logger  = Ic::Logger.create(log_to: "tmp/test-#{described_class}-admin.log", log_mode: 'w', log_level: Logger::DEBUG)
    @logger.info('Group') { @logger.banner(described_class.to_s) }
    options = load_config('spec/login.json')
    options[:user]     = options[:admin_user]     if options.include?(:admin_user)
    options[:password] = options[:admin_password] if options.include?(:admin_password)
    @session = Ic::Session.connect(log_to: @logger, **options)
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

  context('[ADMIN] User Creation') do
    specify 'should be able to create a user' do |example|
      @logger.info('Example') { @logger.banner(example.description) }
      user = Ic::User.create(session: @session, id: 'tempuser', display_name: 'Temp User', extension: '99999')
      expect(user).to be_truthy
      expect(user.id).to eq 'tempuser'
    end
  end

  context('[ADMIN] User Deletion') do
    specify 'should be able to delete a user' do |example|
      @logger.info('Example') { @logger.banner(example.description) }
      user = Ic::User.find(session: @session, id: 'tempuser')
      expect(user).to be_truthy
      expect(user.id).to eq 'tempuser'
      user.delete
      expect(user.id).to be nil
    end
  end
end
