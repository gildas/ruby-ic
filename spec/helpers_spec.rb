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
end
