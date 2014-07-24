require 'rspec'
require 'spec_helper'
require 'ic/logger'

describe 'Logger' do
  before do
    @test_filename = 'tmp/test.log'
    Dir.mkdir(File.dirname(@test_filename)) if ! Dir.exists?(File.dirname(@test_filename))
    Dir.glob('tmp/test*.log*') {|filename| File.delete(filename)}
  end

  specify 'should create null loggers' do
    logger = Ic::Logger.create
    expect(logger).to be_truthy
    logger.error "This text should be ignored"
  end

  specify 'should create loggers on the standard output' do
    expect {
      logger = Ic::Logger.create(log_to: $stdout)
      expect(logger).to be_truthy
      logger.error "This text should be displayed on the standard output"
    }.to output.to_stdout
  end

  specify 'should create loggers on a filename' do
    text = "This text should be written in a file"
    logger = Ic::Logger.create(log_to: @test_filename)
    expect(logger).to be_truthy
    logger.error text
    logger.close
    file = File.open(@test_filename)
    expect(file).to be_a_kind_of File
    content = file.read
    expect(content).to include text
    File.delete(@test_filename)
    expect(File.exists?(@test_filename)).to be false
  end

  specify 'should create loggers on a file' do
    text = "This text should be written in a file"
    file = File.open(@test_filename, 'a')
    logger = Ic::Logger.create(log_to: file)
    expect(logger).to be_truthy
    logger.error text
    logger.close
    file = File.open(@test_filename)
    expect(file).to be_a_kind_of File
    content = file.read
    expect(content).to include text
    File.delete(@test_filename)
    expect(File.exists?(@test_filename)).to be false
  end

  specify 'should create loggers on multiple targets' do
    text = "This text should be written in a file"
    file1 = File.open("#{@test_filename}-01", 'a')
    file2 = File.open("#{@test_filename}-02", 'a')
    logger = Ic::Logger.create(log_to: [file1, file2])
    expect(logger).to be_truthy
    logger.error text
    logger.close
    ["#{@test_filename}-01", "#{@test_filename}-02"].each do |filename|
      file = File.open(filename)
      expect(file).to be_a_kind_of File
      content = file.read
      expect(content).to include text
      File.delete(filename)
      expect(File.exists?(filename)).to be false
    end
  end
end
