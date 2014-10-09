require 'rspec'
require 'spec_helper'

describe 'Helpers' do
  context('String') do
    specify 'should camelize correctly' do |example|
      expect('my_test_string'.to_camel).to eq 'MyTestString'
      expect('my_test_string'.to_camel(lower: true)).to eq 'myTestString'
    end

    specify 'should snakerize correctly' do |example|
      expect('MyTestString'.to_snake).to eq 'my_test_string'
      expect('myTestString'.to_snake).to eq 'my_test_string'
    end
  end

  context('Hash') do
    specify 'should transform JSON to Ruby snake Hashes' do
      have   = { 'myTestKey' => 'Value', 'myTestArray' => [ 'Value1', 'Value2' ] }
      wanted = { my_test_key: 'Value', my_test_array: [ 'Value1', 'Value2' ] }
      expect(have.keys2sym).to eq wanted
    end

    specify 'should transform Ruby snake Hashes to JSON' do
      have   = { my_test_key: 'Value', my_test_array: [ 'Value1', 'Value2' ] }
      wanted = { 'myTestKey' => 'Value', 'myTestArray' => [ 'Value1', 'Value2' ] }
      expect(have.keys2camel(lower: true)).to eq wanted
    end

    specify 'keys2sym should be idempotent' do
      have   = { my_test_key: 'Value', my_test_array: [ 'Value1', 'Value2' ] }
      expect(have.keys2sym).to eq have
    end

    specify 'keys2camel should be idempotent' do
      have   = { 'myTestKey' => 'Value', 'myTestArray' => [ 'Value1', 'Value2' ] }
      expect(have.keys2camel).to eq have
    end
  end
end
