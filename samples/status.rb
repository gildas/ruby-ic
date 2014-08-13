#! /usr/bin/env ruby
require 'optparse'
require 'io/console'
require 'ic'

def prompt_password(prompt='Password: ')
  printf(prompt)
  STDIN.noecho(&:gets).chomp
end

options  = {}
optparse = OptionParser.new do|opts|
  # Set a banner, displayed at the top
  # of the help screen.
  opts.banner = "Usage: status.rb [options] [new-status]"

  # Define the options, and what they do
  options[:verbose] = false
  options[:tail]    = false
  opts.on( '-v', '--verbose', 'Output more information' )               { options[:log_level] = Logger::DEBUG }
  opts.on( '-l', '--logfile FILE', 'Write log to FILE' )                { |file| options[:log_to] = file }
  opts.on('-s', '--server SERVER', 'Connect to the CIC SERVER')         { |server| options[:server] = server }
  opts.on('-u', '--user USER', 'User to connect with')                  { |user| options[:user] = user }
  opts.on('-p', '--password [PASSWORD]', 'Password to connect with')    { |password| options[:password] = password }
  opts.on( '-t', '--tail', 'subscribe to status changes (^C to stop)' ) { options[:tail] = true }

  # This displays the help screen, all programs are
  # assumed to have this option.
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

optparse.parse!
options[:password] = prompt_password unless options[:password]

session = Ic::Session.connect(options)

if !ARGV.empty?
  session.user.status = ARGV.first
end
current_status = session.user.status

if options[:tail]
  observer = session.subscribe(Ic::UserStatusMessage, user: session.user) do |statuses|
    statuses.each do |status|
      next unless status.user_id == session.user.id
      puts "Your status is: #{status}, id=#{status.id}, message=#{status.message}, last change=#{status.changed_at}"
    end
  end
  stop = false
  trap('INT') { stop = true }
  loop until stop
  observer.stop
else
  puts "Your status is: #{current_status}, id=#{current_status.id}, message=#{current_status.message}, last change=#{current_status.changed_at}"
end
