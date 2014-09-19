require 'logger'
require 'time'

module Ic
  module Traceable
    # @!attribute [rw] logger
    # @return [Logger] the logger used in this mixin
    attr_reader :logger
    attr_writer :logger
    alias_method :trace, :logger

    # Creates the mixin's logger
    # @see Ic::Logger
    #
    # @param (see Ic::Logger#create)
    # @param default [#logger] gets the logger from another object
    # @param options [Hash]    absorbs extra parameters we do not use
    # @return (see Ic::Logger#create)
    def create_logger(log_to: nil, log_mode: 'a', log_level: ::Logger::WARN, log_progname: 'ic', shift_age: 0, shift_size: 1048576, log_formatter: nil, default: nil, **options)
      if log_to.nil? && !default.nil? && default.respond_to?(:logger)
        @logger = default.logger
      else
        @logger = Ic::Logger.create(log_to: log_to, log_mode: log_mode, log_level: log_level, log_progname: log_progname, shift_age: shift_age, shift_size: shift_size, log_formatter: log_formatter)
      end
    end
  end

  # The Logger class used by the classes of the Ic library
  class Logger < ::Logger
    # Creates a new Logger object
    #   if log_to is not passed or is nil, the logger will be created on the device #NullIO.
    #
    # @param log_to        [Logger, String, File, StringIO, IO, Array] the device(s) to send log messages to.
    # @param log_mode      [String]                                    the file mode when the device is a File
    # @param log_level     [Enum]                                      the level of logging (See {::Logger})
    # @param log_progname  [String]                                    the program name (See {::Logger})
    # @param shift_age     [Integer, String]                           when to rotate the logs (See {::Logger})
    # @param shift_size    [Integer]                                   the limit in size before rotating the logs (See {::Logger})
    # @param log_formatter [Formatter]                                 the {Formatter} to format the messages before writing to the devices
    # @return              [Logger]
    def self.create(log_to: nil, log_mode: 'a', log_level: Logger::WARN, log_progname: 'ic', shift_age: 0, shift_size: 1048576, log_formatter: nil)
      return Logger.new(NullIO.new) unless log_to
      return log_to if log_to.kind_of? Logger
      devices = self.devices(log_to: log_to, log_mode: log_mode)
      devices = MultiIO.new(devices) if devices.kind_of? Array
      logger  = Logger.new(devices, shift_age, shift_size)
      logger.progname  = log_progname
      logger.level     = log_level
      logger.formatter = log_formatter || Formatter.new
      logger
    end

    # Adds a new context that will be displayed whenever a message is sent to the devices
    # @param context [Hash] each context has a key and a value
    def add_context(**context)
      formatter.add_context(context) if formatter.respond_to? :add_context
    end

    # Removes a context from being displayed in messages
    # @param (see #add_context)
    def remove_context(**context)
      formatter.remove_context(context) if formatter.respond_to? :remove_context
    end

    # Builds a banner with the given text
    # @param title            [String] the text to place in the banner
    # @param banner_character [String] the character to fill the banner
    # @param length           [Fixnum] the total length of the banner
    def banner(title, banner_character: '=', length: 120)
      [banner_character * 10, title, banner_character * (length - 13 - title.size)].join(' ')
    end

    private
    # Resolves the values from log_to into IO objects
    # @param log_to   [Array, String, File, StringIO, IO] the destinations for logging
    # @param log_mode [String]                            the file mode when creating a File
    # @return [Array<IO>, IO]                             resolved destinations as IO objects
    def self.devices(log_to: nil, log_mode: 'a')
      case log_to
        when Array              then log_to.map {|target| self.devices(log_to: target)}.flatten
        when String             then File.open(log_to, log_mode)
        when File, StringIO, IO then log_to
        else raise InvalidArgumentError, "#{log_to}"
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
  private_constant :Formatter

  class NullIO
    def write(*args) ; end
    def close        ; end
  end
  private_constant :NullIO

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
  private_constant :MultiIO
end
