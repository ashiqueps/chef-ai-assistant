# frozen_string_literal: true

require 'chef-ai-assistant/version'
require 'chef-ai-assistant/azure_openai'
require 'chef-ai-assistant/command'
require 'chef-ai-assistant/integration_context'
require 'chef-ai-assistant/credentials_manager'
require 'chef-ai-assistant/utils/cli_helper'
require 'chef-ai-assistant/utils/prompt_renderer'
require 'chef-ai-assistant/commands/ai'

module ChefAiAssistant
  class Error < StandardError; end

  # Configuration for the gem
  class << self
    attr_writer :configuration, :integration_context

    # Always return a configuration object, initializing if necessary
    def configuration
      @configuration ||= Configuration.new
    end

    # Always return an integration context, initializing with defaults if necessary
    def integration_context
      @integration_context ||= IntegrationContext.new(
        configuration.integration_gem_name,
        configuration.integration_gem_version,
        configuration.integration_gem_description
      )
    end

    def configure
      self.configuration ||= Configuration.new
      yield(configuration) if block_given?

      # Always ensure integration context is updated with latest config
      # even if not explicitly set in the configure block
      self.integration_context = IntegrationContext.new(
        configuration.integration_gem_name,
        configuration.integration_gem_version,
        configuration.integration_gem_description
      )
    end

    def reset
      self.configuration = Configuration.new
      self.integration_context = nil
    end

    # Helper method to allow other gems to register the AI commands
    # Now also tracks the parent gem information for context
    def register_commands_with(app_class, options = {})
      # Ensure configuration exists before trying to configure
      self.configuration ||= Configuration.new

      # Parse options that affect configuration
      configuration.strict_context_aware = options[:strict_context] if options.key?(:strict_context)

      # This is a legacy method kept for backward compatibility
      # Delegate to the CliHelper which now handles both configuration and registration
      begin
        ChefAiAssistant::Utils::CliHelper.configure_for_gem(app_class, nil, options)
      rescue StandardError => e
        # Provide detailed error information but don't crash
        puts "Warning: Failed to register AI commands with #{app_class}: #{e.message}"
        puts e.backtrace.join("\n") if ENV['DEBUG']

        # Still attempt to register commands even if configuration failed
        begin
          ChefAiAssistant::Commands::Ai.register_with(app_class)
        rescue StandardError => cmd_error
          puts "Error: Failed to register commands: #{cmd_error.message}" if ENV['DEBUG']
        end
      end
    end

    # Helper method to register commands with relaxed context awareness
    # This will allow the AI to answer questions about the entire Chef ecosystem
    def register_commands_with_relaxed_context(app_class, gem_name = nil)
      # Ensure configuration exists before trying to configure
      self.configuration ||= Configuration.new

      # Set the context to relaxed/non-strict before delegating
      configuration.strict_context_aware = false

      # Configure with the app class and gem name
      ChefAiAssistant::Utils::CliHelper.configure_for_gem(app_class, gem_name, { strict_context: false })
    rescue StandardError => e
      # Provide detailed error information but don't crash
      puts "Warning: Failed to register AI commands with #{app_class}: #{e.message}"
      puts e.backtrace.join("\n") if ENV['DEBUG']

      # Still attempt to register commands even if configuration failed
      # This provides resilience when components are missing
      begin
        ChefAiAssistant::Commands::Ai.register_with(app_class)
      rescue StandardError => cmd_error
        puts "Error: Failed to register commands: #{cmd_error.message}" if ENV['DEBUG']
      end
    end

    private

    # These methods are kept for backward compatibility but are no longer used directly
    def determine_gem_name(app_class)
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
      # Use the constant from IntegrationContext if available
      if IntegrationContext.const_defined?(:KNOWN_GEMS)
        return IntegrationContext::KNOWN_GEMS[gem_name] || 'Chef ecosystem tool'
      end

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

  # Configuration class to store Azure OpenAI settings and integration context
  class Configuration
    attr_accessor :api_key, :api_version, :azure_endpoint, :deployment_name, :integration_gem_name,
                  :integration_gem_version, :integration_gem_description, :strict_context_aware

    def initialize
      # Set defaults for all configuration values
      @api_key = nil
      @api_version = '2023-05-15' # Default API version
      @azure_endpoint = nil
      @deployment_name = nil
      @integration_gem_name = 'chef' # Default to chef
      @integration_gem_version = 'unknown'
      @integration_gem_description = 'Chef command-line tool for infrastructure automation'
      @strict_context_aware = true # By default, context awareness is strict (tool-specific)

      # Try to load credentials from file
      load_credentials_from_file

      # Also check for environment variables as a fallback
      load_credentials_from_env
    end

    # Helper method to load credentials from file
    def load_credentials_from_file
      if defined?(CredentialsManager) && CredentialsManager.respond_to?(:credentials_exist?) && CredentialsManager.credentials_exist?
        begin
          creds = CredentialsManager.load_credentials
          @api_key ||= creds['azure_openai_api_key']
          @api_version ||= creds['azure_openai_api_version']
          @azure_endpoint ||= creds['azure_openai_endpoint']
          @deployment_name ||= creds['azure_openai_deployment_name']
        rescue StandardError => e
          # Log the error but continue - we've already set defaults
          puts "Warning: Failed to load credentials from file: #{e.message}" if ENV['DEBUG']
        end
      end
    rescue StandardError => e
      # If CredentialsManager isn't loaded or has issues, just log it
      puts "Warning: Error checking credentials file: #{e.message}" if ENV['DEBUG']
    end

    # Helper method to load credentials from environment variables
    def load_credentials_from_env
      # Use env vars if available and not already set
      @api_key ||= ENV['AZURE_OPENAI_API_KEY']
      @api_version ||= ENV['AZURE_OPENAI_API_VERSION'] || '2023-05-15'
      @azure_endpoint ||= ENV['AZURE_OPENAI_ENDPOINT']
      @load_credentials_from_env ||= ENV['AZURE_OPENAI_DEPLOYMENT_NAME']
    end

    # Check if credentials are valid enough to make API calls
    def credentials_valid?
      !(@api_key.nil? || @azure_endpoint.nil? || @deployment_name.nil?)
    end

    # Helper to provide integration info as a string
    def integration_info
      if @integration_gem_name
        "#{@integration_gem_name} #{@integration_gem_version}"
      else
        'chef (default)'
      end
    end
  end

  # Helper method to create an Azure OpenAI client with robust error handling
  def self.openai_client
    # Ensure configuration exists
    self.configuration ||= Configuration.new

    # Check if required fields are present
    unless configuration.api_key && configuration.azure_endpoint && configuration.deployment_name
      # Try to load credentials again in case they were added after startup
      configuration.load_credentials_from_file
      configuration.load_credentials_from_env

      # If still not available, raise a helpful error
      unless configuration.api_key && configuration.azure_endpoint && configuration.deployment_name
        missing = []
        missing << 'API key' unless configuration.api_key
        missing << 'Azure endpoint' unless configuration.azure_endpoint
        missing << 'Deployment name' unless configuration.deployment_name

        raise "Missing required OpenAI configuration: #{missing.join(', ')}"
      end
    end

    # Create the client with all required parameters
    AzureOpenAI.new(
      api_key: configuration.api_key,
      api_version: configuration.api_version || '2023-05-15',
      azure_endpoint: configuration.azure_endpoint,
      deployment_name: configuration.deployment_name
    )
  rescue LoadError => e
    # This occurs if the AzureOpenAI class isn't loaded
    raise "Failed to load Azure OpenAI client: #{e.message}. Make sure chef-ai-assistant is properly installed."
  rescue StandardError => e
    # Provide a more helpful error message
    raise "Failed to create OpenAI client: #{e.message}. Please run 'chef ai setup' to configure credentials."
  end
end
