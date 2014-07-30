require 'logger'
require 'time'

module Ic
  module Traceable
    attr_reader :logger

    def initialize_logger(options = {})
      @logger = Ic::Logger.create(options)
    end

    alias_method :trace, :logger
  end

  class Logger < ::Logger
    def self.create(options={})
      targets = targets(options)
      if targets.empty?
        logger = NullLogger.new()
      elsif targets.size == 1
        return targets.first if targets.first.kind_of?(Logger)
        logger = Logger.new(targets.first)
      else
        logger = Logger.new(MultiIO.new(targets))
      end
      logger.progname  = options[:log_progname]  || 'Ic'
      logger.level     = options[:log_level] || Logger::WARN
      logger.formatter = Ic::Formatter.new
      logger
    end

    def add_context(context = {})
      formatter.add_context(context)
    end

    private
    def self.targets(options={})
      return [] if ! options[:log_to]
      case options[:log_to]
        when Logger             then [ options[:log_to] ]
        when Array              then options[:log_to].map {|target| targets(log_to: target)}.flatten
        when String             then [ File.open(options[:log_to], 'a') ]
        when File, StringIO, IO then [ options[:log_to] ]
        else []
      end
    end
  end

  class Formatter < ::Logger::Formatter
    def initialize
      super
      @contexts = {}
    end

    def call(severity, time, progname, message)
      context_items =  @contexts.collect { |context| "#{context.first}:#{context.last}"}
      context_info  = context_items.empty? ? '' : "[#{context_items.join(',')}]"
      "%s [%d][%s]%s %5s: %s\n" % [time.iso8601, $$, progname, context_info, severity, msg2str(message)]
    end

    def add_context(context = {})
      @contexts.merge! context
    end

    def remove_context(context)
      @contexts.delete(context)
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
