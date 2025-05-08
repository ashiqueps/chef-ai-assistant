require "chef-ai-assistant/version"
require "chef-ai-assistant/azure_openai"
require "chef-ai-assistant/command"
require "chef-ai-assistant/commands/ai"
require "dotenv"

# Load environment variables from .env file if it exists
Dotenv.load if defined?(Dotenv)

module ChefAiAssistant
  class Error < StandardError; end
  
  # Configuration for the gem
  class << self
    attr_accessor :configuration
    
    def configure
      self.configuration ||= Configuration.new
      yield(configuration) if block_given?
    end
    
    def reset
      self.configuration = Configuration.new
    end
    
    # Helper method to allow other gems to register the AI commands
    def register_commands_with(app_class)
      ChefAiAssistant::Commands::Ai.register_with(app_class)
    end
  end
  
  # Configuration class to store Azure OpenAI settings
  class Configuration
    attr_accessor :api_key, :api_version, :azure_endpoint, :deployment_name
    
    def initialize
      @api_key = ENV['AZURE_OPENAI_API_KEY']
      @api_version = ENV['AZURE_OPENAI_API_VERSION'] || '2023-05-15'
      @azure_endpoint = ENV['AZURE_OPENAI_ENDPOINT']
      @deployment_name = ENV['AZURE_OPENAI_DEPLOYMENT_NAME']
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