# frozen_string_literal: true

require 'wtflogger/scribe'
require 'wtfalert/alerts'
require 'filelock'
#
# @module Wtfalert
#
module Wtfalert
  #
  # @class Alerter
  #
  class Alerter < Wtflogger::Scribe

    def initialize(
      caller: 'wtf-alerter',
      level: 'warn',
      screen: false,
      options: {}
    )
      super(:caller => caller, :level => level, :screen => screen)

      @debug = level =~ %r{debug} ? true : false

      dn = options.key?(:domian) ? options[:domain] : %x(hostname -d).chomp
      opts = {
        :store => '/opt/wtfapp/var/lib',
        :smtphost => 'localhost',
        :domain => dn,
        :to => "root@#{dn}",
        :from => "root@#{dn}",
        :throttle => 86_400,
        :debug => @debug
      }.merge(options)

      debug "debug: #{@debug}"
      @alerts = Wtfalert::Alerts.new(self, opts)
      # counters for testing purposes only
      @errors = @cleared = @throttled = @sent = 0
      # TODO: internal alert if not specified store
    end

    def error(message)
      super
      @errors += 1
    end

    def fatal(message)
      super
      @errors += 1
    end

    # Clears an alerter where:
    #  args {
    #     key      => 'unique alert key', # required
    #     subject  => 'subject',          # optional
    #     message  => 'message',          # optional
    #     filename => 'pathname',         # optional read file into message
    #  }
    #
    def clear(args)
      alert_action('clear', args)
    end

    # Raises an alerter where:
    #  args {
    #     key      => 'unique alert key', # required
    #     subject  => 'subject',          # optional
    #     message  => 'message',          # optional
    #     filename => 'pathname',         # optional read file into message
    #  }
    #
    def raise(args)
      alert_action('raise', args)
    end

    # Prints the loaded alert data:
    def dump
      alert_action('dump')
    end

    # Emails message for specified alert
    def send_alert(args, body)
      @mailer.send(args, body)
    end

    def status
      # simplifies my rspec tests
      raised = @sent + @throttled
      rv = "raised: #{raised} cleared: #{@cleared} sent: #{@sent} throttled: #{@throttled} errors: #{@errors}"
      debug rv
      rv
    end

    private

    def clear_action(args)
      debug 'clear_action called'
      raise ArgumentError, 'args paramater required for clear_action' if args.nil?

      raise ArgumentError, 'Failed to clear alert. Missing key argument.' unless args.key?(:key)

      @cleared += @alerts.clear(args)
    end

    def raise_action(args)
      debug 'raise_action called'
      raise ArgumentError, 'args paramater required for raise_action' if args.nil?

      raise ArgumentError, 'Failed to raise alert. Missing key argument.' unless args.key?(:key)

      message = @alerts.raise(args)
      warn message
      if message =~ %r{^Alert throttled:}
        @throttled += 1
      else
        @sent += 1
      end
    rescue Error => e
      error e.backtrace if @debug
      error e.message
    end

    def do_action(action, args)
      case action
      when 'dump'
        pp @alerts
      when 'raise'
        raise_action(args)
      when 'clear'
        clear_action(args)
      else
        fatal "Unknown action: #{action}"
      end
    end

    def alert_action(action, args = nil)
      debug "alert_action called for #{action}"
      locked = false
      lockname = @alerts.lockname
      Filelock lockname, :wait => 60, :timeout => 55 do |file|
        locked = true
        # puts "file object is a: " + file.class.to_s
        file.truncate 0
        file.write Process.pid
        @alerts.load
        do_action(action, args)
        @alerts.save
      end
      raise "Failed to obtain lock #{lockname}" unless locked
    rescue StandardError => e
      if @debug
        e.backtrace.each do |bt|
          debug bt
        end
      end
      error e.message
    end
  end
end
