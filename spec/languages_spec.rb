require 'rspec'

describe 'Language' do
  before do
    @config = load_config('spec/login.json')
    @config[:log_level] = Logger::DEBUG
  end

  specify 'should get a list of supported languages' do
    @config[:log_to] = "tmp/test-Languages-#{Time.now.strftime('%Y%m%d%H%M%S%L')}.log"
    session = Ic::Session.connect(@config)
    expect(session).to be_truthy
    expect(session.connected?).to be true
    begin
      languages = Ic::Language.find_all(session)
      expect(languages).to be_truthy
      expect(languages.empty?).to be false
#      expect(languages.find_index {|language| language.id == 'en-us'}).to be > -1
    ensure
      session.disconnect
      expect(session.connected?).to be false
    end
  end
end
