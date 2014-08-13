require 'rspec'
require 'spec_helper'

describe Ic::License do
  before do
    @logger  = Ic::Logger.create(log_to: "tmp/test-#{described_class}.log", log_mode: 'w', log_level: Logger::DEBUG)
    @logger.info('Group') { @logger.banner(described_class.to_s) }
    @session = Ic::Session.connect(from: 'spec/login.json', log_to: @logger)
    expect(@session).to be_truthy
    expect(@session.connected?).to be true
  end

  specify 'should be acquired' do |example|
    @logger.info('Example') { @logger.banner(example.description) }
    begin
      licenses = @session.acquire_licenses('I3_ACCESS_CLIENT')
      expect(licenses).to be_truthy
      expect(licenses.size).to be >= 1
      expect(licenses.find {|license| license.id == 'I3_ACCESS_CLIENT'}).to be_truthy
    ensure
      @session.disconnect
      expect(@session.connected?).to be false
    end
  end
end