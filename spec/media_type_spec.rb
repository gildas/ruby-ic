require 'rspec'
require 'spec_helper'

describe 'Media Types' do

  specify 'should have a default' do
    expect(Ic::MediaType::DEFAULT).to be_truthy
  end

  specify 'should accept strings' do
    expect(Ic::MediaType.from_string('default')).to eq Ic::MediaType::DEFAULT
    expect(Ic::MediaType.from_string('none')).to eq Ic::MediaType::NONE
    expect(Ic::MediaType.from_string('Call')).to eq Ic::MediaType::CALL
  end

  specify 'should accept single values from hashes' do
    expect(Ic::MediaType.from_hash(media_types: 'Call')).to eq [ Ic::MediaType::CALL ]
  end

  specify 'should accept multiple values from hashes' do
    expect(Ic::MediaType.from_hash(media_types: ['Call', Ic::MediaType::SMS])).to eq [ Ic::MediaType::CALL, Ic::MediaType::SMS ]
  end
end

