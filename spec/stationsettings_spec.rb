require 'rspec'
require 'spec_helper'

describe Ic::StationSettings do
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

  specify 'should create workstation' do
    @config[:log_to] = "tmp/test-#{described_class}-Workstation.log"
    station = Ic::WorkstationSettings.new(id: @config[:workstation])
    expect(station.id).to eq @config[:workstation]
   end
end
