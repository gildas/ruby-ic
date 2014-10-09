require 'rspec'
require 'spec_helper'

describe Ic::Message do
  before(:context) do
    @logger  = Ic::Logger.create(log_to: "tmp/test-#{described_class}.log", log_mode: 'w', log_level: Logger::DEBUG)
    @logger.info('Group') { @logger.banner(described_class.to_s) }
  end

  after(:context) do
    @logger.close
  end

  context('UserStatusMessage') do
    specify 'should be created from JSON' do |example|
      @logger.info('Example') { @logger.banner(example.description) }
      data = {
        :__type => "urn:inin.com:status:userStatusMessage",
        :userStatusList =>
        [
          {
            :userId         => "yuri.ebihara",
            :statusId       => "Gone Home",
            :statusChanged  => "20140919T104555Z",
            :icServers      => [],
            :stations       => [],
            :loggedIn       => false,
            :onPhone        => false,
            :onPhoneChanged => "20140919T034547Z"
          }
        ],
        :isDelta=>false
      }.keys2sym
      message = Ic::Message.from_json(data, log_to: @logger)
      expect(message).to be_truthy
      expect(message).to be_kind_of(Ic::UserStatusMessage)
      expect(message.statuses.size).to eq(1)
    end
  end
end
