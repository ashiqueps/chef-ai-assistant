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
    attr_accessor :configuration, :integration_context

    def configure
      self.configuration ||= Configuration.new
      yield(configuration) if block_given?

      # Set integration context if options are provided
      return unless configuration.integration_gem_name

      self.integration_context = IntegrationContext.new(
        configuration.integration_gem_name,
        configuration.integration_gem_version,
        configuration.integration_gem_description
      )
    end

    def reset
      self.configuration = Configuration.new
    end

    # Helper method to allow other gems to register the AI commands
    # Now also tracks the parent gem information for context
    def register_commands_with(app_class, options = {})
      # This is a legacy method kept for backward compatibility
      # Delegate to the CliHelper which now handles both configuration and registration
      ChefAiAssistant::Utils::CliHelper.configure_for_gem(app_class, nil, options)
    end

    # Helper method to register commands with relaxed context awareness
    # This will allow the AI to answer questions about the entire Chef ecosystem
    def register_commands_with_relaxed_context(app_class, gem_name = nil)
      ChefAiAssistant::Utils::CliHelper.configure_for_gem(app_class, gem_name, { strict_context: false })
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
      # Try to load credentials from file
      if CredentialsManager.credentials_exist?
        begin
          creds = CredentialsManager.load_credentials
          @api_key = creds['azure_openai_api_key']
          @api_version = creds['azure_openai_api_version']
          @azure_endpoint = creds['azure_openai_endpoint']
          @deployment_name = creds['azure_openai_deployment_name']
        rescue StandardError => _e
          # Fall back to nil values if there's an issue loading credentials
        end
      end

      # Set default for api_version if not set
      @api_version ||= '2023-05-15'

      # Integration context defaults to nil
      @integration_gem_name = nil
      @integration_gem_version = nil
      @integration_gem_description = nil

      # By default, context awareness is strict (tool-specific)
      @strict_context_aware = true
    end
  end

  # Helper method to create an Azure OpenAI client
  def self.openai_client
    AzureOpenAI.new(
      api_key: configuration.api_key,
      api_version: configuration.api_version,
      azure_endpoint: configuration.azure_endpoint,
      deployment_name: configuration.deployment_name
    )
  end
end
