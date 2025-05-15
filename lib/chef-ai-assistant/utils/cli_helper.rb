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
          # Skip all credential checks if in debug or help mode
          unless ARGV.any? { |arg| ['--help', '-h', '--version', '-v', 'setup'].include?(arg) }
            begin
              # Check if API credentials are set, but don't exit if they aren't
              # This allows command registration even without credentials (they'll be checked later when running commands)
              check_credentials(false)
            rescue StandardError => e
              puts "Warning: Credential check failed: #{e.message}" if ENV['DEBUG']
              # Continue anyway - don't exit
            end
          end

          # If no gem_name is provided, try to determine it from the app_class
          begin
            gem_name ||= determine_gem_name_from_app_class(app_class)
          rescue StandardError => e
            # If we can't determine gem name, use a default
            gem_name = 'chef'
            puts "Warning: Could not determine gem name from #{app_class}: #{e.message}" if ENV['DEBUG']
          end

          # Only show spinner in interactive mode
          use_spinner = $stdout.isatty && !ENV['CI'] && !ENV['TEST']

          spinner = if use_spinner
                      TTY::Spinner.new(
                        "[:spinner] #{Rainbow("Configuring ChefAiAssistant for #{gem_name}...").bright.cyan}", format: :dots
                      )
                    end

          spinner&.auto_spin

          begin
            # Determine parent gem info from the app_class with robust error handling
            begin
              gem_name = determine_gem_name_from_app_class(app_class)
            rescue StandardError => e
              gem_name ||= 'chef'
              puts "Warning: Error determining gem name: #{e.message}" if ENV['DEBUG']
            end

            begin
              gem_version = determine_gem_version(gem_name)
            rescue StandardError => e
              gem_version = 'unknown'
              puts "Warning: Error determining gem version: #{e.message}" if ENV['DEBUG']
            end

            begin
              gem_description = determine_gem_description(gem_name)
            rescue StandardError => e
              gem_description = 'Chef ecosystem tool'
              puts "Warning: Error determining gem description: #{e.message}" if ENV['DEBUG']
            end

            # Get strict context mode setting from options (default: true)
            strict_context = options.key?(:strict_context) ? options[:strict_context] : true

            # Configure with integration context
            begin
              ChefAiAssistant.configure do |config|
                # Set integration context
                config.integration_gem_name = gem_name
                config.integration_gem_version = gem_version
                config.integration_gem_description = gem_description
                config.strict_context_aware = strict_context
              end
            rescue StandardError => e
              puts "Warning: Error configuring ChefAiAssistant: #{e.message}" if ENV['DEBUG']
              # Continue anyway - the module will use defaults
            end

            # Register the AI commands with the app class
            begin
              ChefAiAssistant::Commands::Ai.register_with(app_class)
            rescue StandardError => e
              puts "Error: Failed to register commands: #{e.message}"
              puts e.backtrace.join("\n") if ENV['DEBUG']
              # Don't fail completely - the main CLI might still work
            end

            # Debug output if requested
            if ENV['DEBUG']
              puts "Debug: Class name = #{app_class.name}"
              puts "Debug: Detected gem = #{ChefAiAssistant.integration_context.parent_gem_name}"
              puts "Debug: Gem version = #{ChefAiAssistant.integration_context.parent_gem_version}"
            end

            spinner&.success('(✓)')
          rescue StandardError => e
            spinner&.error('(✗)')
            puts "Warning: Error during configuration: #{e.message}"
            puts e.backtrace.join("\n") if ENV['DEBUG']
            # Don't exit - allow the application to continue even if AI setup fails
          end
        end

        private

        def check_credentials(exit_on_failure = true)
          # Skip credential check for help, version flags and setup command
          skip_check = false

          # Check for common help and version patterns
          skip_check ||= ARGV.any? { |arg| ['setup', '--help', '-h', '--version', '-v'].include?(arg) }

          # Check for ai setup, ai help, etc. patterns
          if ARGV.length >= 2 && ARGV[0] == 'ai'
            skip_check ||= ['setup', '--help', '-h', '--version', '-v'].include?(ARGV[1])
          end

          # Check for ai with global help or version flags
          if ARGV.length >= 1 && ARGV[0] == 'ai'
            skip_check ||= ARGV.any? { |arg| ['--help', '-h', '--version', '-v'].include?(arg) }
          end

          return true if skip_check
          return true if ChefAiAssistant::CredentialsManager.credentials_exist?

          # If we get here, credentials are needed and not found
          begin
            if $stdout.isatty && !ENV['CI'] && !ENV['TEST']
              prompt = TTY::Prompt.new
              prompt.error('Azure OpenAI credentials not found')
              prompt.say("Please run 'chef ai setup' to configure your credentials")
            else
              # In non-TTY environment, just print without formatting
              puts 'Error: Azure OpenAI credentials not found'
              puts "Please run 'chef ai setup' to configure your credentials"
            end
          rescue StandardError => e
            # Even if TTY prompt fails, still show a simple message
            puts "Error: Azure OpenAI credentials not found (#{e.message})"
            puts "Please run 'chef ai setup' to configure your credentials"
          end

          exit 1 if exit_on_failure
          false
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
