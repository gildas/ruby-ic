require 'socket'
require 'json'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

desc "Links the configuration file to the current network"
task :prep_config do
  my_config = nil
  Socket.getifaddrs.map { |i| i.addr.ip_address if i.addr.ipv4? }.compact.each do |local_ip|
    Dir.glob('spec/login-*.json').each do |filename|
      config = { 'network' => '' }
      File.open(filename) { |file| config = JSON.parse(file.read) }
      if local_ip =~ /#{config['network']}/
        file 'spec/login.json' => filename do
          cp filename, 'spec/login.json', :verbose => true
        end
        desc 'matches login.json per network'
        task :config_file => 'spec/login.json'
        my_config = filename
        puts "Testing over #{local_ip} with #{filename}"
        break
      end
    end
  end
  raise NotImplementedError, "Cannot find a configuration for any of my netoworks" unless my_config
end
desc "Runs the RSpec tests after linking the configuration"
task :test => [:prep_config, :spec]
