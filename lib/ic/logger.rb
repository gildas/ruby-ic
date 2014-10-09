require 'logger'
require 'time'

module Ic
  # This interface allows classes to add tracing.
  #
  # @example how to add tracing to a class:
  #  class MyClass
  #    include Traceable
  #
  #    def initialize(arguments, **options)
  #      @id = 'my_id'
  #      self.create_logger(log_to: STDOUT, log_level: Logger::DEBUG)
  #      logger.add_context(topic: @id)
  #    end
  #
  #    def my_method
  #      trace.info "I am in my method"
  #      trace.debug('Topic') { "Tracing stuff with a topic" }
  #    end
  #  end
  module Traceable
    # @!attribute [rw] logger
    # @return [Logger] the logger
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
    # Initializes a Formatter
    def initialize
      super
      @contexts = {}
    end

    # Formats tracing data into a String
    #
    # @param severity [String]   The trace level
    # @param time     [Datetime] The Datetime of that trace
    # @param progname [String]   THe program name
    # @param message  [String]   The trace message
    # @return [String] The formatted trace message
    def call(severity, time, progname, message)
      context_items =  @contexts.collect { |context| "#{context.first}:#{context.last}"}
      context_info  = context_items.empty? ? '' : "[#{context_items.join(',')}]"
      "%s [%d][%s]%s %5s: %s\n" % [time.iso8601, $$, progname, context_info, severity, msg2str(message)]
    end

    # Adds contexts to be traced
    #
    # @param context [Hash] contextual data
    def add_context(context = {})
      @contexts.merge! context
    end

    # Stop tracing contexts
    #
    # @param context [Hash] contextual data
    def remove_context(context)
      @contexts.delete(context)
    end
  end
  private_constant :Formatter

  # An IO class that sends all traces to nowhere
  class NullIO
    # Writes its arguments to nowhere
    def write(*args) ; end
    # Closes nothing...
    def close        ; end
  end
  private_constant :NullIO

  # An IO class that sends all traces to several IO
  class MultiIO
    # Initializes a MultiIO
    #
    # @param targets [Array<IO>] List of IO objects
    def initialize(targets = [])
      @targets = targets
    end

    # Writes its arguments to all registered IO objects
    #
    # @param args [Array] Arguments to write
    def write(*args)
      @targets.each {|target| target.write(*args)}
    end

    # Closes all registered IO objects
    def close
      @targets.each(&:close)
    end
  end
  private_constant :MultiIO
end
