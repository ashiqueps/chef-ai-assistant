# frozen_string_literal: true

require_relative 'lib/chef-ai-assistant/version'

Gem::Specification.new do |spec|
  spec.name          = 'chef-ai-assistant'
  spec.version       = ChefAiAssistant::VERSION
  spec.authors       = ['Ashique Saidalavi', 'Nikhil Gupta', 'Sachin Jain']
  spec.email         = ['Ashique.Saidalavi@progress.com', 'Nikhil.Gupta@progress.com', 'Sachin.Jain@progress.com']

  spec.summary       = 'AI Assistant for Chef'
  spec.description   = 'A Ruby gem that provides AI assistant capabilities for Chef'
  spec.homepage      = 'https://github.com/ashiqueps/chef-ai-assistant'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.metadata['allowed_push_host'] = "TODO: Set to your gem server 'https://rubygems.org'"
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.10'

  # Runtime dependencies
  spec.add_dependency 'dotenv', '~> 2.8'
  spec.add_dependency 'ruby-openai', '~> 5.0'
  spec.add_dependency 'tty-prompt', '~> 0.23'
  spec.add_dependency 'tty-spinner', '~> 0.9'
end
