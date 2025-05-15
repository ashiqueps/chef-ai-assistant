# frozen_string_literal: true

require 'bundler/setup'
require 'chef-ai-assistant'
require 'tty-spinner'
require 'tty-prompt'
require 'rainbow'

module ChefAiAssistant
  module Utils
    # Helper module for CLI utilities shared across binaries
    module CliHelper
      class << self
        # Configure the AI assistant for a specific gem
        def configure_for_gem(app_class, gem_name = nil, options = {})
          # Check if API credentials are set
          check_credentials

          # If no gem_name is provided, try to determine it from the app_class
          gem_name ||= determine_gem_name_from_app_class(app_class)

          # Configure the AI assistant
          spinner = TTY::Spinner.new(
            "[:spinner] #{Rainbow("Configuring ChefAiAssistant for #{gem_name}...").bright.cyan}", format: :dots
          )
          spinner.auto_spin

          begin
            # Determine parent gem info from the app_class
            gem_name = determine_gem_name_from_app_class(app_class)
            gem_version = determine_gem_version(gem_name)
            gem_description = determine_gem_description(gem_name)

            # Get strict context mode setting from options (default: true)
            strict_context = options.key?(:strict_context) ? options[:strict_context] : true

            # Configure with integration context
            ChefAiAssistant.configure do |config|
              # Set integration context
              config.integration_gem_name = gem_name
              config.integration_gem_version = gem_version
              config.integration_gem_description = gem_description
              config.strict_context_aware = strict_context
            end

            # Register the AI commands with the app class
            ChefAiAssistant::Commands::Ai.register_with(app_class)

            # Debug output if requested
            if ENV['DEBUG']
              puts "Debug: Class name = #{app_class.name}"
              puts "Debug: Detected gem = #{ChefAiAssistant.integration_context.parent_gem_name}"
              puts "Debug: Gem version = #{ChefAiAssistant.integration_context.parent_gem_version}"
            end

            spinner.success('(✓)')
          rescue StandardError => e
            spinner.error('(✗)')
            TTY::Prompt.new.error(e.message)
            puts e.backtrace if ENV['DEBUG']
            exit 1
          end
        end

        private

        def check_credentials
          # Skip credential check for help and version flags
          if ARGV.length >= 2 && ARGV[0] == 'ai' &&
             ['setup', '--help', '-h', '--version', '-v'].include?(ARGV[1])
            return
          end

          # Also handle the case where ai has a global help or version flag
          if ARGV.length >= 1 && ARGV[0] == 'ai' &&
             (ARGV.include?('--help') || ARGV.include?('-h') ||
              ARGV.include?('--version') || ARGV.include?('-v'))
            return
          end

          # Otherwise check credentials
          return if ChefAiAssistant::CredentialsManager.credentials_exist?

          prompt = TTY::Prompt.new
          prompt.error('Azure OpenAI credentials not found')
          prompt.say("Please run 'chef ai setup' to configure your credentials")
          exit 1
        end

        # Attempt to determine the gem name from the class name
        def determine_gem_name_from_app_class(app_class)
          # Extract the gem name from the class name
          class_name = app_class.name.to_s

          gem_patterns = {
            'knife' => [/Chef::Knife/i, /Knife::/i],
            'chef-cli' => [/ChefCLI/i, /ChefCli/i],
            'test-kitchen' => [/TestKitchen/i, /Kitchen/i],
            'inspec' => [/InSpec/i],
            'habitat' => [/Habitat/i, /Hab/i]
          }

          gem_patterns.each do |gem_name, patterns|
            return gem_name if patterns.any? { |pattern| class_name.match?(pattern) }
          end

          # Default to 'chef' if we can't determine the gem
          'chef'
        end

        # Get gem version
        def determine_gem_version(gem_name)
          # Try to get the version from the loaded gem
          Gem::Specification.find_by_name(gem_name).version.to_s
        rescue Gem::LoadError
          # If the gem is not found, return unknown
          'unknown'
        end

        # Get gem description
        def determine_gem_description(gem_name)
          descriptions = {
            'chef' => 'Chef command-line tool for infrastructure automation',
            'chef-cli' => 'Chef Command Line Interface for workflow automation',
            'knife' => 'Chef knife tool for Chef Server interaction and node management',
            'test-kitchen' => 'Test Kitchen for automated testing of infrastructure code',
            'inspec' => 'InSpec for compliance automation and security testing',
            'habitat' => 'Habitat for application packaging and runtime management',
            'hab' => 'Habitat for application packaging and runtime management'
          }

          descriptions[gem_name] || 'Chef ecosystem tool'
        end
      end
    end
  end
end
