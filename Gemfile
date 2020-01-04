# frozen_string_literal: true

source ENV['GEM_SOURCE'] || 'https://rubygems.org'
source 'https://gem.fury.io/qs5779/' do
  gem 'wtflogger', '~> 0.1'
end

def check_for_journal
  return false unless RUBY_PLATFORM =~ /linux/
  File.directory?('/run/systemd/journal')
end

journal_require = check_for_journal

gem 'logging-journald', require: journal_require

# Specify your gem's dependencies in wtfalert.gemspec
gemspec
