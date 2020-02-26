# frozen_string_literal: true

# more core and stlibs

require 'getoptlong'

# our own code

require 'wtfalert/alerter'

module Wtfalert
  # @class Runner
  class Runner
    def initialize
      @debug = @verbose = false
    end

    def long_options
      GetoptLong.new(
        ['--debug', '-d', GetoptLong::NO_ARGUMENT],
        ['--verbose', '-v', GetoptLong::NO_ARGUMENT],
        ['--script', '-s', GetoptLong::REQUIRED_ARGUMENT],
        ['--show', '-S', GetoptLong::NO_ARGUMENT],
        ['--version', '-V', GetoptLong::NO_ARGUMENT],
        ['--help', '--man', '-h', GetoptLong::NO_ARGUMENT]
      )
    end

    def usage(exc = 0)
      puts <<-USG
      usage: #{@basenm} [-d] [-h] [-s caller] [-S] [-v] [-V]
        where:
          -d|--debug         - specify debug mode
          -h|--help          - show this message and exit
          -s|--script caller - specify caller name (defaults to wtfalert)
          -S|--show          - show contents of the alerts storage
          -v|--verbose       - add verbosity
          -V|--version       - show version and exit
      USG
      exit exc
    end

    def create
      level = if @debug
                'debug'
              elsif @verbose
                'info'
              else
                'warn'
              end
      Alerter.new(:caller => @cscript, :level => level, :screen => STDOUT.isatty)
    end

    def show
      @alerter ||= create
      @alerter.dump
    end

    # rubocop:disable Metrics/MethodLength
    def parse_options(opts)
      action = nil

      opts.each do |opt, arg|
        case opt
        when '--help'
          usage
        when '--version'
          puts "#{@basenm} #{VERSION}"
          exit 0
        when '--show'
          action = 'show'
        when '--script'
          @cscript = arg
        when '--verbose'
          @verbose = true
        when '--debug'
          @debug = true
          @verbose = true
        end
      end

      case action
      when 'show'
        show
      else
        usage
      end
    end
    # rubocop:enable Metrics/MethodLength

    def run(basenm)
      @cscript = @basenm = basenm
      parse_options long_options
    end
  end
end
