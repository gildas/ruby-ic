require 'rspec'
require 'spec_helper'

describe Ic::Subscriber do
  before(:context) do
    @logger  = Ic::Logger.create(log_to: "tmp/test-#{described_class}.log", log_mode: 'w', log_level: Logger::DEBUG)
    @logger.info('Group') { @logger.banner(described_class.to_s) }
    @session = Ic::Session.connect(from: 'spec/login.json', log_to: @logger)
    expect(@session).to be_truthy
    expect(@session.connected?).to be true
    @current_status = @session.user.status
    expect(@current_status).to be_truthy
    expect(@current_status.id).to be_instance_of String
  end

  after(:context) do
    if (@session)
      @session.user.status = @current_status
      new_status = @session.user.status
      expect(new_status).to be_truthy
      expect(new_status.id).to eq @current_status.id
      @session.disconnect
      expect(@session.connected?).to be false
    end
    @logger.close
  end

  context('User') do
    specify 'should be notified when status changes' do |example|
      @logger.info('Example') { @logger.banner(example.description) }
      mutex = Mutex.new
      status_updated = ConditionVariable.new
      @session.user.subscribe to: @session, about: Ic::UserStatusMessage do |message|
        @logger.info('observer') { "Got #{message.statuses.size} status(es)"}
        message.statuses.each do |status|
          @logger.info('observer') { "Status for #{status.user_id}: #{status}"}
          next unless status.user_id == @session.user.id
          if status.id == 'Do Not disturb'
            @logger.debug('observer') { 'Found the expected status'}
            mutex.synchronize do
              status_updated.signal
            end
            break
          end
        end
      end
      @session.user.status = 'Do Not disturb'
      @logger.info('Example') { 'Waiting for the change to be seen by the observer'}
      mutex.synchronize do
        status_updated.wait(mutex, 5)
      end
      new_status = @session.user.status
      expect(new_status).to be_truthy
      expect(new_status.id).to eq 'Do Not disturb'
      @session.user.unsubscribe from: @session
    end
  end
end
