require 'json'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new


def local_ip
  begin
    require 'socket'
    turn_off_reverse_DNS = true
    orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, turn_off_reverse_DNS

    UDPSocket.open do |socket|
      socket.connect '64.233.187.99', 1
      socket.addr.last
    end
  ensure
    Socket.do_not_reverse_lookup = orig
  end
end

desc "Links the configuration file to the current network"
task :prep_config do
  my_config = nil
  my_ip     = ENV['network'] || local_ip
  task :config_file do ; end
  Dir.glob('spec/login-*.json').each do |filename|
    config = { 'network' => '' }
    File.open(filename) { |file| config = JSON.parse(file.read) }
    if my_ip =~ /#{config['network']}/
      file 'spec/login.json' => filename do
        cp filename, 'spec/login.json', :verbose => true
      end
      desc 'matches login.json per network'
      task :config_file => 'spec/login.json'
      my_config = filename
      break
    end
  end
  raise NotImplementedError, "Cannot find a configuration for #{my_ip}" unless my_config
end
desc "Runs the RSpec tests after linking the configuration"
task :test => [:prep_config, :spec]
