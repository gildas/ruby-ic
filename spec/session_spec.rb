require 'rspec'
require 'spec_helper'

describe 'Session' do
  before do
    @config = load_config('spec/login.json')
    @config[:log_level] = Logger::DEBUG
  end

  context 'valid server and credentials' do
    specify 'should connect and disconnect' do
      @config[:log_to] = "tmp/test-Session-Connect-#{Time.now.strftime('%Y%m%d%H%M%S%L')}.log"
      session = Ic::Session.connect(@config)
      expect(session).to be_truthy
      expect(session.connected?).to be true
      session.disconnect
      expect(session.connected?).to be false
    end
  end

  context 'Server Information' do
    specify 'should get a version from the CIC server' do
      @config[:log_to] = "tmp/test-Session-Version-#{Time.now.strftime('%Y%m%d%H%M%S%L')}.log"
      session = Ic::Session.new(@config)
      expect(session).to be_truthy
      version = session.version
      expect(version).to_not be nil
    end

    specify 'should get a feature list from the CIC server' do
      @config[:log_to] = "tmp/test-Session-Features-#{Time.now.strftime('%Y%m%d%H%M%S%L')}.log"
      session = Ic::Session.new(@config)
      expect(session).to be_truthy
      features = session.features
      expect(features).to be_truthy
      expect(features).to be_kind_of(Enumerable)
    end

    specify 'should contain the feature "connection"' do
      @config[:log_to] = "tmp/test-Session-Feature?-#{Time.now.strftime('%Y%m%d%H%M%S%L')}.log"
      session = Ic::Session.new(@config)
      expect(session).to be_truthy
      expect(session.feature?('connection')).to be true
    end

    specify 'the feature "connection" should at least be version 1' do
      @config[:log_to] = "tmp/test-Session-Feature-#{Time.now.strftime('%Y%m%d%H%M%S%L')}.log"
      session = Ic::Session.new(@config)
      expect(session).to be_truthy
      feature = session.feature('connection')
      expect(feature[:version]).to be >= 1
    end

    specify 'should not contain the feature "acme"' do
      @config[:log_to] = "tmp/test-Session-!Feature?-#{Time.now.strftime('%Y%m%d%H%M%S%L')}.log"
      session = Ic::Session.new(@config)
      expect(session).to be_truthy
      expect(session.feature?('acme')).to be false
    end
  end

  context 'Station Connection' do
    specify 'should not exist by default' do
      @config[:log_to] = "tmp/test-Session-Station-#{Time.now.strftime('%Y%m%d%H%M%S%L')}.log"
      session = Ic::Session.connect(@config)
      expect(session).to be_truthy
      expect(session.connected?).to be true
      expect { session.station }.to raise_error(Ic::StationNotFoundError)
      session.disconnect
      expect(session.connected?).to be false
    end

    specify 'should be assignable' do
      @config[:log_to] = "tmp/test-Session-Station=-#{Time.now.strftime('%Y%m%d%H%M%S%L')}.log"
      session = Ic::Session.connect(@config)
      expect(session).to be_truthy
      expect(session.connected?).to be true
      session.station(type: :remote_number, number: '+13178723000', persistent: false)
      station = session.station
      expect(station[:stationSetting]).to be 3
      expect(station[:id]).to eq '+13178723000'
      session.disconnect
      expect(session.connected?).to be false
    end
  end
end