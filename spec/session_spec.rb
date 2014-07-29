require 'rspec'
require 'spec_helper'

describe 'Session' do
  before do
    @config = load_config('spec/login.json')
    @config[:log_level] = Logger::DEBUG

    #default station configurations
    @config[:workstation]   ||= '7001'
    @config[:remotestation] ||= 'gildasmobile'
    @config[:remotenumber]  ||= '+13178723000'
    @config[:persistent]    ||= false
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

    specify 'should allow workstation' do
      @config[:log_to] = "tmp/test-Session-Workstation-#{Time.now.strftime('%Y%m%d%H%M%S%L')}.log"
      session = Ic::Session.connect(@config)
      expect(session).to be_truthy
      expect(session.connected?).to be true
      begin
        session.station = Ic::WorkstationSettings.new(id: @config[:workstation])
        station = session.station
        expect(station[:stationSetting]).to be 1
        expect(station[:id]).to eq @config[:workstation]
      ensure
        session.disconnect
        expect(session.connected?).to be false
      end
    end

    specify 'should allow workstation with media types' do
      @config[:log_to] = "tmp/test-Session-Workstation-#{Time.now.strftime('%Y%m%d%H%M%S%L')}.log"
      session = Ic::Session.connect(@config)
      expect(session).to be_truthy
      expect(session.connected?).to be true
      begin
        session.station = Ic::WorkstationSettings.new(id: @config[:workstation], media_types: %w{ call sms })
        station = session.station
        expect(station[:stationSetting]).to be 1
        expect(station[:id]).to eq @config[:workstation]
      ensure
        session.disconnect
        expect(session.connected?).to be false
      end
    end

    specify 'should allow remote station' do
      @config[:log_to] = "tmp/test-Session-RemoteStation-#{Time.now.strftime('%Y%m%d%H%M%S%L')}.log"
      session = Ic::Session.connect(@config)
      expect(session).to be_truthy
      expect(session.connected?).to be true
      begin
        session.station = Ic::RemoteWorkstationSettings.new(id: @config[:remotestation])
        station = session.station
        expect(station[:stationSetting]).to be 2
        expect(station[:id]).to eq (@config[:remotestation])
      ensure
        session.disconnect
        expect(session.connected?).to be false
      end
    end

    specify 'should allow remote number' do
      @config[:log_to] = "tmp/test-Session-RemoteNumber-#{Time.now.strftime('%Y%m%d%H%M%S%L')}.log"
      session = Ic::Session.connect(@config)
      expect(session).to be_truthy
      expect(session.connected?).to be true
      begin
        session.station = Ic::RemoteNumberSettings.new(id: @config[:remotenumber], persistent: @config[:persistent])
        station = session.station
        expect(station[:stationSetting]).to be 3
        expect(station[:id]).to eq (@config[:remotenumber])
      ensure
        session.disconnect
        expect(session.connected?).to be false
      end
    end

    specify 'should be able to disconnect from all stations' do
      @config[:log_to] = "tmp/test-Session-NoStation-#{Time.now.strftime('%Y%m%d%H%M%S%L')}.log"
      session = Ic::Session.connect(@config)
      expect(session).to be_truthy
      expect(session.connected?).to be true
      begin
        session.station = Ic::WorkstationSettings.new(id: @config[:workstation])
        station = session.station
        expect(station[:stationSetting]).to be 1
        expect(station[:id]).to eq @config[:workstation]
        session.station = nil
        expect { session.station }.to raise_error(Ic::StationNotFoundError)
      ensure
        session.disconnect
        expect(session.connected?).to be false
      end
    end
  end
end