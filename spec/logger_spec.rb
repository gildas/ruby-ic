require 'rspec'
require 'spec_helper'

describe 'Logger' do
  before do
    @test_filename = 'tmp/test.log'
    Dir.mkdir(File.dirname(@test_filename)) unless Dir.exists?(File.dirname(@test_filename))
    File.delete(@test_filename)             if     File.exists?(@test_filename)
  end

  specify 'should create null loggers' do
    logger = Ic::Logger.create
    expect(logger).to be_truthy
    logger.error 'This text should be ignored'
  end

  specify 'should create loggers on the standard output' do
    expect {
      logger = Ic::Logger.create(log_to: $stdout)
      expect(logger).to be_truthy
      logger.error 'This text should be displayed on the standard output'
    }.to output.to_stdout
  end

  specify 'should create support log levels' do
    expect {
      logger = Ic::Logger.create(log_to: $stdout, log_level: Logger::DEBUG)
      expect(logger).to be_truthy
      logger.debug 'This text should be displayed on the standard output'
    }.to output.to_stdout
  end

  specify 'should create support changes to log levels' do
    expect {
      logger = Ic::Logger.create(log_to: $stdout)
      expect(logger).to be_truthy
      expect(logger.info?).to be false
      logger.info  'This text should not be displayed on the standard output'
      logger.level = Logger::INFO
      expect(logger.info?).to be true
      logger.info 'This text should be displayed on the standard output'
    }.to output.to_stdout
  end

  specify 'should create loggers on a filename' do
    text = 'This text should be written in a file'
    begin
      logger = Ic::Logger.create(log_to: @test_filename)
      expect(logger).to be_truthy
      logger.error text
      logger.close
      file = File.open(@test_filename)
      expect(file).to be_a_kind_of File
      content = file.read
      expect(content).to include text
    ensure
      File.delete(@test_filename)
      expect(File.exists?(@test_filename)).to be false
    end
  end

  specify 'should create loggers on a file' do
    text = 'This text should be written in a file'
    begin
      file = File.open(@test_filename, 'w')
      logger = Ic::Logger.create(log_to: file)
      expect(logger).to be_truthy
      logger.error text
      logger.close
      file = File.open(@test_filename)
      expect(file).to be_a_kind_of File
      content = file.read
      expect(content).to include text
    ensure
      File.delete(@test_filename)
      expect(File.exists?(@test_filename)).to be false
    end
  end

  specify 'should create loggers on multiple targets' do
    text      = 'This text should be written in a file'
    filenames = [ "#{@test_filename}-01", "#{@test_filename}-02" ]
    begin
      files  = filenames.collect {|filename| File.open(filename, 'w')}
      logger = Ic::Logger.create(log_to: files)
      expect(logger).to be_truthy
      logger.error text
      logger.close
      filenames.each do |filename|
        file = File.open(filename)
        expect(file).to be_a_kind_of File
        content = file.read
        expect(content).to include text
      end
    ensure
      filenames.each do |filename|
        File.delete(filename)
        expect(File.exists?(filename)).to be false
      end
    end
  end

  specify 'should support contextual information' do
    text = 'This text should be written in a file'
    begin
      logger = Ic::Logger.create(log_to: @test_filename)
      expect(logger).to be_truthy
      logger.add_context(id: 'test')
      logger.error text
      logger.close
      file = File.open(@test_filename)
      expect(file).to be_a_kind_of File
      content = file.read
      expect(content).to include text
      expect(content).to include '[id:test]'
    ensure
      File.delete(@test_filename)
      expect(File.exists?(@test_filename)).to be false
    end
  end
end
