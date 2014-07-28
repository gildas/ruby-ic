require 'logger'
require 'time'

module Ic
  class Logger < ::Logger
    def self.create(options={})
      targets = targets(options)
      if targets.empty?
        logger = NullLogger.new()
      elsif targets.size == 1
        logger = Logger.new(targets.first)
      else
        logger = Logger.new(MultiIO.new(targets))
      end
      logger.progname  = options[:log_progname]  || 'Ic'
      logger.level     = options[:log_level] || Logger::WARN
      logger.formatter = Ic::Formatter.new
      logger
    end

    private
    def self.targets(options={})
      return [] if ! options[:log_to]
      case options[:log_to]
        when Array              then options[:log_to].map {|target| targets(log_to: target)}.flatten
        when String             then [ File.open(options[:log_to], 'a') ]
        when File, StringIO, IO then [ options[:log_to] ]
        else []
      end
    end
  end

  class Formatter < ::Logger::Formatter
    def call(severity, time, progname, message)
      "%s [%d][%s] %5s: %s\n" % [time.iso8601, $$, progname, severity, msg2str(message)]
    end
  end

  class NullLogger < ::Logger
    def initialize(*args)  ; end
    def add(*args, &block) ; end
  end

  class MultiIO
    def initialize(targets = [])
      @targets = targets
    end

    def write(*args)
      @targets.each {|target| target.write(*args)}
    end

    def close
      @targets.each(&:close)
    end
  end
end
