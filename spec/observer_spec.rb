require 'rspec'
require 'spec_helper'

describe Ic::Observer do
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
    @session.user.status = @current_status
    new_status = @session.user.status
    expect(new_status).to be_truthy
    expect(new_status.id).to eq @current_status.id
    @session.disconnect
    expect(@session.connected?).to be false
    @logger.close
  end

  context('logger') do
    specify 'should be notified when status changes' do |example|
      @logger.info('Example') { @logger.banner(example.description) }
      mutex = Mutex.new
      status_updated = ConditionVariable.new
      status_observer = @session.subscribe(Ic::UserStatusMessage, user: @session.user) do |statuses|
        @logger.info('observer') { "Got #{statuses.size} status(es)"}
        statuses.each do |status|
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
      status_observer.stop
    end
  end
end
