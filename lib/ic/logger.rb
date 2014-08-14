require 'logger'
require 'time'

module Ic
  module Traceable
    attr_reader :logger

    #
    # @param options
    def logger=(options = {})
      @logger = Ic::Logger.create(options)
    end

    alias_method :trace, :logger
  end

  # The Logger class used by the classes of the Ic library
  class Logger < ::Logger
    DEFAULT_SHIFT_AGE  = 0
    DEFAULT_SHIFT_SIZE = 1048576

    # Creates a new Logger object
    #
    #   @param log_to [Logger, String, File, StringIO, IO, Array] the devices to send log messages to.
    #   @param log_level [Enum] the level of logging
    #   @param log_progname [String]
    #   @param shift_age [Integer, String]
    #   @param shift_size [Integer]
    #   @param log_formatter [Formatter]
    #   @return [Logger]
    def self.create(options={})
      return Logger.new(NullIO.new) unless options[:log_to]
      return options[:log_to] if options[:log_to].kind_of? Logger
      devices = self.devices(options)
      devices = MultiIO.new(devices) if devices.kind_of? Array
      logger  = Logger.new(devices, options[:shift_age] || DEFAULT_SHIFT_AGE, options[:shift_size] || DEFAULT_SHIFT_SIZE)
      logger.progname  = options[:log_progname]  || 'Ic'
      logger.level     = options[:log_level]     || Logger::WARN
      logger.formatter = options[:log_formatter] || Formatter.new
      logger
    end

    def add_context(context = {})
      formatter.add_context(context)
    end

    def remove_context(context = {})
      formatter.remove_context(context)
    end

    # Builds a banner with the given text
    # @param title            [String] the text to place in the banner
    # @param banner_character [String] the character to fill the banner
    # @param length           [Fixnum] the total length of the banner
    def banner(title, banner_character: '=', length: 120)
      [banner_character * 10, title, banner_character * (length - 13 - title.size)].join(' ')
    end

    private
    def self.devices(options={})
      case options[:log_to]
        when Array              then options[:log_to].map {|target| self.devices(log_to: target)}.flatten
        when String             then File.open(options[:log_to], options[:log_mode] || 'a')
        when File, StringIO, IO then options[:log_to]
        else raise InvalidArgumentError, "#{options[:log_to]}"
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

  class NullIO
    def write(*args) ; end
    def close        ; end
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
