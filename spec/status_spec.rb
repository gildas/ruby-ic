require 'rspec'
require 'spec_helper'

describe Ic::Status do
  before(:context) do
    @logger  = Ic::Logger.create(log_to: "tmp/test-#{described_class}.log", log_mode: 'w', log_level: Logger::DEBUG)
    @logger.info('Group') { @logger.banner(described_class.to_s) }
    @session = Ic::Session.connect(from: 'spec/login.json', log_to: @logger)
    expect(@session).to be_truthy
    expect(@session.connected?).to be true
  end

  after(:context) do
    expect(@session).to be_truthy
    @session.disconnect
    expect(@session.connected?).to be false
    @logger.close
  end

  context 'logger' do
    specify 'should have a list' do |example|
      @logger.info('Example') { @logger.banner(example.description) }
      statuses = Ic::Status.find_all(session: @session)
      expect(statuses).to be_truthy
      expect(statuses.empty?).to be false
      expect(statuses.find_index {|status| status.id == 'Available'}).to be > -1
    end

    specify 'should have a list in French' do |example|
      @logger.info('Example') { @logger.banner(example.description) }
      session = Ic::Session.connect(from: 'spec/login.json', language: 'fr-FR', log_to: @logger)
      expect(session).to be_truthy
      expect(session.connected?).to be true
      begin
        statuses = Ic::Status.find_all(session: session)
        expect(statuses).to be_truthy
        expect(statuses.empty?).to be false
        expect(statuses.find_index {|status| status.id == 'Available'}).to be > -1
      ensure
        session.disconnect
        expect(session.connected?).to be false
      end
    end

    specify 'should have a list for logged in user' do |example|
      @logger.info('Example') { @logger.banner(example.description) }
      statuses = Ic::Status.find_all_ids(session: @session, user: @session.user)
      expect(statuses).to be_truthy
      expect(statuses.empty?).to be false
      expect(statuses.find_index {|status_id| status_id == 'Available'}).to be > -1
    end

    specify 'should get the status of the logged in user' do |example|
      @logger.info('Example') { @logger.banner(example.description) }
      status = @session.user.status
      expect(status).to be_truthy
      expect(status.id).to be_instance_of String
    end

    specify 'should set the status of the logged in user' do |example|
      @logger.info('Example') { @logger.banner(example.description) }
      current_status = @session.user.status
      expect(current_status).to be_truthy
      expect(current_status.id).to be_instance_of String
      @session.user.status = 'Do Not disturb'
      new_status = @session.user.status
      expect(new_status).to be_truthy
      expect(new_status.id).to eq 'Do Not disturb'
      @session.user.status = current_status
      new_status = @session.user.status
      expect(new_status).to be_truthy
      expect(new_status.id).to eq current_status.id
    end
  end
end
