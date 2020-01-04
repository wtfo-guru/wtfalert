# frozen_string_literal: true

require 'wtfalert/mailer'
require 'wtfalert/store'
#
# @module Wtfalert
#
module Wtfalert
  #
  # @class Alerter
  #
  class Alerts
    def initialize(logger, opts)
      @stores = {}
      @dirty = false
      @data = {}
      @data_pathname = nil
      @logger = logger
      @mailer = Wtfalert::Mailer.new(opts[:to], opts[:from], opts[:smtphost])
      @store = Wtfalert::Store.new(opts[:store])

      @throttle = opts[:throttle]
    end

    def lockname
      @store.lockname
    end

    def raise(args, body = 'no message specified')
      @logger.debug 'Alerts::raise called'
      bump_count(args[:key])
      @dirty = true
      @data[args[:key]][:last] = init_int @data[args[:key]][:last]
      if !throttle?(args[:key], args[:throttle])
        @mailer.compose(args, body)
        "Alert sent for: #{args[:key]}"
      else
        throttled = @data[args[:key]][:throttled]
        s = @mailer.compose_subject(args)
        "Alert throttled: #{s} (#{throttled} times)"
      end
    end

    def clear(args)
      @logger.debug 'Alerts::clear called'
      key = args[:key]
      last, throttled = clear_key(key)
      rc = 0
      if last.negative?
        @logger.debug "key not found: #{key}"
      elsif last.positive?
        body = "Alert cleared (throttled #{throttled} times) for key: #{key}"
        args[:subject] = "#{key} alert cleared"
        @mailer.compose(args, body)
        warn "Alert cleared for key: #{key}"
        rc = 1
      else
        @logger.debug "nothing to clear for key: #{key}"
      end
      rc
    end

    def save
      return unless @dirty

      @store.save @data
      @dirty = false
    end

    def load
      @data = @store.load
      @dirty = false
    end

    private

    def bump_count(key)
      if @data.key?(key)
        @data[key][:count] = bump @data[key][:count]
      else
        @data[key] = {}
        @data[key][:count] = 1
      end
    end

    def throttle?(key, throttle)
      throttle = init_int(throttle, @throttle)
      now = Time.now.to_i
      if (now - @data[key][:last]) > throttle
        @data[key][:throttled] = 0
        @data[key][:last] = now
        false
      else
        @data[key][:throttled] = bump @data[key][:throttled]
        true
      end
    end

    def clear_key(key)
      last = -1
      throttled = -1
      if @data.key?(key)
        throttled = 0
        last = 0
        if @data[key].key?(:last)
          last = @data[key][:last]
          if last != 0
            throttled = @data[key][:throttled]
            @data[key][:last] = 0
            @data[key][:throttled] = 0
            @dirty = true
          end
        end
      end
      [last, throttled]
    end

    def init_int(value, initial = 0)
      return value if value.is_a? Integer

      return initial if value.nil?

      @logger&.warn 'reinitialized non integer value to 0 (should never happen)'
      0
    end

    def bump(value)
      return value + 1 if value.is_a? Integer

      return 1 if value.nil?

      @logger&.warn 'reinitialized non integer value to 1 (should never happen)'
      1
    end
  end
end
