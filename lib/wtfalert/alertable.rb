# frozen_string_literal: true

require 'wtfalert/alerter'

#
# @module Wtfalert
#
module Wtfalert
  #
  # @class Alertable provdes alerting and logging for other gems
  #
  class Alertable
    attr_reader :exit_code, :error_count

    def initialize(opts)
      @error_count = @exit_code = 0
      @sudo_warning = false
      @options = {
        :test => false,
        :verbose => 0,
        :debug => 0,
        :caller => self.class.name,
        :alerter => nil
      }.merge(opts)

      level = if debug?
                'debug'
              elsif verbose?
                'info'
              else
                'warn'
              end
      @options[:alerter] ||= Wtfalert::Alerter.new(:caller => @options[:caller], :level => level, :screen => STDOUT.isatty)
    end

    def debug?
      @options[:debug].positive?
    end

    def verbose?
      @options[:verbose].positive?
    end

    def loud?
      debug? || verbose?
    end

    def log_error(message, fatal = false)
      @error_count += 1
      alerter = @options[:alerter]
      if alerter.nil?
        warn message
      elsif fatal
        alerter.fatal message
      else
        alerter.error message
      end
    end

    def log_debug(message)
      alerter = @options[:alerter]
      if alerter.nil?
        puts message if debug?
      else
        alerter.debug message
      end
    end

    def log_info(message)
      alerter = @options[:alerter]
      if alerter.nil?
        puts message if verbose?
      else
        alerter.info message
      end
    end

    def log_warn(message)
      alerter = @options[:alerter]
      if alerter.nil?
        warn message
      else
        alerter.warn message
      end
    end

    def send_alert(args)
      @error_count += 1
      alerter = @options[:alerter]
      if @options[:test]
        warn 'TEST: ' + args[:key] + ': ' + args[:subject]
      elsif alerter.nil?
        warn args[:key] + ': ' + args[:subject]
      else
        alerter.send args
      end
    end

    def clear_alert(args)
      alerter = @options[:alerter]
      alerter&.clear args
    end

    def warn_sudo(message)
      return if @sudo_warning

      warn 'Permission error, perhaps you can try again using sudo?' if message =~ %r{Permission} && Process.uid.positive?
      @sudo_warning = true
    end
  end
end
