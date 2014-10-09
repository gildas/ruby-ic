require 'rspec'
require 'spec_helper'

describe Ic::Session do
  before do
    @config = load_config('spec/login.json')
    @config[:log_level] = Logger::DEBUG
    [:application,
     :server,
     :user,
     :password,
     :workstation,
     :remotestation,
     :remotenumber].each do |key|
      raise ArgumentError, "Missing: #{key}" unless @config[key]
    end
     @config[:persistent] ||= false
  end

  context 'initialization' do
    specify 'can be configured manually' do
      @config[:log_to] = "tmp/test-#{described_class}-Initialize-manually.log"
      session = Ic::Session.new(server: 'my-cic', user: 'admin', password: 'S3cr3t')
      expect(session).to be_truthy
      expect(session.server).to  eq 'my-cic'
      expect(session.user.id).to eq 'admin'
    end

    specify 'can be configured via @config' do
      @config[:log_to] = "tmp/test-#{described_class}-Initialize-config.log"
      session = Ic::Session.new(@config)
      expect(session).to be_truthy
      expect(session.server).to  eq @config[:server]
      expect(session.user.id).to eq @config[:user]
    end
  end

  context 'valid server and credentials' do
    specify 'should connect and disconnect' do
      @config[:log_to] = "tmp/test-#{described_class}-Connect.log"
      session = Ic::Session.connect(@config)
      expect(session).to be_truthy
      expect(session.connected?).to be true
      session.disconnect
      expect(session.connected?).to be false
    end
  end

  context 'Server Information' do
    specify 'should get a version from the CIC server' do
      @config[:log_to] = "tmp/test-#{described_class}-Version.log"
      session = Ic::Session.new(@config)
      expect(session).to be_truthy
      version = session.version
      expect(version).to_not be nil
    end

    specify 'should get a feature list from the CIC server' do
      @config[:log_to] = "tmp/test-#{described_class}-Features.log"
      session = Ic::Session.new(@config)
      expect(session).to be_truthy
      features = session.features
      expect(features).to be_truthy
      expect(features).to be_kind_of(Enumerable)
    end

    specify 'should contain the feature "connection"' do
      @config[:log_to] = "tmp/test-#{described_class}-Feature?.log"
      session = Ic::Session.new(@config)
      expect(session).to be_truthy
      expect(session.feature?('connection')).to be true
    end

    specify 'the feature "connection" should at least be version 1' do
      @config[:log_to] = "tmp/test-#{described_class}-Feature.log"
      session = Ic::Session.new(@config)
      expect(session).to be_truthy
      feature = session.feature(feature: 'connection')
      expect(feature[:version]).to be >= 1
    end

    specify 'should not contain the feature "acme"' do
      @config[:log_to] = "tmp/test-#{described_class}-!Feature?.log"
      session = Ic::Session.new(@config)
      expect(session).to be_truthy
      expect(session.feature?('acme')).to be false
    end
  end

  context 'Station Connection' do
    specify 'should not exist by default' do
      @config[:log_to] = "tmp/test-#{described_class}-Station.log"
      session = Ic::Session.connect(@config)
      expect(session).to be_truthy
      expect(session.connected?).to be true
      expect { session.station }.to raise_error(Ic::StationNotFoundError)
      session.disconnect
      expect(session.connected?).to be false
    end

    specify 'should allow workstation' do
      @config[:log_to] = "tmp/test-#{described_class}-Workstation.log"
      session = Ic::Session.connect(@config)
      expect(session).to be_truthy
      expect(session.connected?).to be true
      begin
        session.station = Ic::WorkstationSettings.new(id: @config[:workstation])
        station = session.station
        expect(station[:station_setting]).to be 1
        expect(station[:id]).to eq @config[:workstation]
      ensure
        session.disconnect
        expect(session.connected?).to be false
      end
    end

    specify 'should allow workstation with media types' do
      @config[:log_to] = "tmp/test-#{described_class}-Workstation.log"
      session = Ic::Session.connect(@config)
      expect(session).to be_truthy
      expect(session.connected?).to be true
      begin
        session.station = Ic::WorkstationSettings.new(id: @config[:workstation], media_types: %w{ call sms })
        station = session.station
        expect(station[:station_setting]).to be 1
        expect(station[:id]).to eq @config[:workstation]
      ensure
        session.disconnect
        expect(session.connected?).to be false
      end
    end

    specify 'should allow remote station' do
      @config[:log_to] = "tmp/test-#{described_class}-RemoteStation.log"
      session = Ic::Session.connect(@config)
      expect(session).to be_truthy
      expect(session.connected?).to be true
      begin
        session.station = Ic::RemoteWorkstationSettings.new(id: @config[:remotestation])
        station = session.station
        expect(station[:station_setting]).to be 2
        expect(station[:id]).to eq (@config[:remotestation])
      ensure
        session.disconnect
        expect(session.connected?).to be false
      end
    end

    specify 'should allow remote number' do
      @config[:log_to] = "tmp/test-#{described_class}-RemoteNumber.log"
      session = Ic::Session.connect(@config)
      expect(session).to be_truthy
      expect(session.connected?).to be true
      begin
        session.station = Ic::RemoteNumberSettings.new(id: @config[:remotenumber], persistent: @config[:persistent])
        station = session.station
        expect(station[:station_setting]).to be 3
        expect(station[:id]).to eq (@config[:remotenumber])
      ensure
        session.disconnect
        expect(session.connected?).to be false
      end
    end

    specify 'should be able to disconnect from all stations' do
      @config[:log_to] = "tmp/test-#{described_class}-NoStation.log"
      session = Ic::Session.connect(@config)
      expect(session).to be_truthy
      expect(session.connected?).to be true
      begin
        session.station = Ic::WorkstationSettings.new(id: @config[:workstation])
        station = session.station
        expect(station[:station_setting]).to be 1
        expect(station[:id]).to eq @config[:workstation]
        session.station = nil
        expect { session.station }.to raise_error(Ic::StationNotFoundError)
      ensure
        session.disconnect
        expect(session.connected?).to be false
      end
    end
  end

  context 'Unique Authentication Token' do
    specify 'should be obtainable' do
      @config[:log_to] = "tmp/test-#{described_class}-Token.log"
      session = Ic::Session.connect(@config)
      expect(session).to be_truthy
      expect(session.connected?).to be true
      begin
        require 'securerandom'

        token = session.unique_auth_token(seed: SecureRandom.uuid)
        expect(token).to be_instance_of String
      ensure
        session.disconnect
        expect(session.connected?).to be false
      end
    end
  end
end
