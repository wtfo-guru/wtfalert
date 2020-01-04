# frozen_string_literal: true

require 'mail'

#
# @module Wtfalert
#
module Wtfalert
  #
  # @class Mailer
  #
  class Mailer
    def initialize(to, from, smtphost)
      @to = to.nil? ? 'root@%s' % domain_name : to
      @from = from.nil? ? 'root@%s' % domain_name : from
      @smtphost = smtphost.nil? ? 'localhost' : smtphost
    end

    # Emails message for specified alert
    #  args {
    #     key      => 'unique alert key', # required
    #     subject  => 'subject',          # optional
    #     to       => 'email',            # optional
    #     from     => 'email',            # optional read file into message
    #  }
    #  body => 'body of message'          # required
    #
    def send(args, body)
      mail = Mail.new

      mail.from = args.key?('from') ? args['from'] : @from
      mail.to = args.key?('to') ? args['to'] : @to
      mail.subject = compose_subject(args)
      mail.body = body
      mail.delivery_method :sendmail

      mail.deliver
    end

    # Sysadmins need to know which host alerted
    def compose_subject(args)
      @myhost ||= Socket.gethostname
      if args.key?(:subject)
        if args[:subject] =~ %r{#{@myhost}}
          args[:subject]
        else
          args[:subject] + " on #{@myhost}"
        end
      else
        "#{args[:key]} alert on #{@myhost}"
      end
    end

    def compose(args, body)
      opts = {
        :to => @to,
        :from => @from,
      }.merge(args)
      compose_message(opts, body)
    end

    def read_file(fpn)
      File.readable?(args[:filename]) ? File.read(fpn) : "File not (found|readable): #{fpn}\n"
    end

    def compose_message(args, default)
      msg = args.key?(:message) ? args[:message] : ''

      if args.key?(:filename)
        msg += read_file(args[:filename])
      end
      msg = default if msg.empty? && !default.nil?
      msg = 'No message specified' if msg.empty?
      send(args, msg)
    end
  end
end
