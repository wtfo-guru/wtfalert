# frozen_string_literal: true
dir = File.expand_path('..', __FILE__)
lib = File.expand_path('lib', dir)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wtfalert/version'

Gem::Specification.new do |spec|
  spec.name          = 'wtfalert'
  spec.version       = Wtfalert::VERSION
  spec.authors       = ['Quien Sabe']
  spec.email         = ['qs5779@mail.com']

  spec.summary       = 'ruby gem to facilitate alerting'
  spec.description   = <<-HEREDOC
  Alerting tool that supports logging, and throttling of alerts. For example
  let's say I have a script that check every hour to see that puppet is running.
  Throttling can allow the alert to only be reported ( via email ) every x times, say
  24 to get one email per day. If the check clears a clear notice is sent and the throttle reset.
  HEREDOC

  spec.homepage      = 'https://github.com/wtfo-guru/wtfalert'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/CHANGLOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(dir) do
    %x(git ls-files -z).split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.required_ruby_version = '>= 2.3.3'

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.74'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.35'

  spec.add_runtime_dependency 'filelock', '~> 1.1'
  spec.add_runtime_dependency 'mail', '~> 2.7'
  spec.add_runtime_dependency 'wtflogger', '~> 0.1'
end
