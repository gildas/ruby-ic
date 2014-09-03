require 'socket'
require 'json'
require 'bundler/gem_tasks'
require 'yard'
require 'rspec/core/rake_task'

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb']
end

RSpec::Core::RakeTask.new

desc "Builds the tags"
task :ctags do
  %x[ git ls-files | ctags --tag-relative --sort=no  --exclude=.idea -L - -f ".git/tags" ]
end

desc "Assigns the proper config file depending on the current network"
task :config_file do
  sources   = Dir.glob('spec/login-*.json')
  if !sources.empty?
    File.delete('spec/login.json') if File.exists? 'spec/login.json'
    my_config = nil
    addresses = []
    addresses << ENV['network'] if ENV['network']
    addresses += Socket.getifaddrs.map { |i| i.addr.ip_address if i.addr.ipv4? }.compact
    raise ArgumentError, "Cannot find any network address to work with" if addresses.empty?
    addresses.each do |local_ip|
      sources.each do |filename|
        config = { 'network' => '' }
        File.open(filename) { |file| config = JSON.parse(file.read) }
        if local_ip =~ /#{config['network']}/
          cp filename, 'spec/login.json', :verbose => true
          my_config = filename
          puts "Testing over #{local_ip} with #{filename}"
          break
        end
      end
    end
    raise NotImplementedError, "Cannot find a configuration for any of my networks (#{addresses.join(', ')})" unless my_config
  end
end

desc "Runs the RSpec tests after linking the configuration"
task :test => [:config_file, :spec]
