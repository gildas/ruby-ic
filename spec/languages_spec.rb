require 'rspec'
require 'spec_helper'

describe Ic::Language do
  before(:context) do
    @logger  = Ic::Logger.create(log_to: "tmp/test-#{described_class}.log", log_mode: 'w', log_level: Logger::DEBUG)
    @logger.info('Group') { @logger.banner(described_class.to_s) }
    @session = Ic::Session.connect(from: 'spec/login.json', log_to: @logger)
    expect(@session).to be_truthy
    expect(@session.connected?).to be true
  end

  after(:context) do
    @session.disconnect
    expect(@session.connected?).to be false
    @logger.close
  end

  context 'logger' do
    specify 'should get a list of supported languages' do |example|
      @logger.info('Example') { @logger.banner(example.description) }
      languages = Ic::Language.find_all(@session)
      expect(languages.find {|language| language.id == 'en-US'}).to be_truthy
    end
  end
end
