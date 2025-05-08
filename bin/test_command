#!/usr/bin/env ruby

require "bundler/setup"
require "dotenv/load"
require "chef-ai-assistant"

# Check if API credentials are set
unless ENV['AZURE_OPENAI_API_KEY'] && ENV['AZURE_OPENAI_ENDPOINT'] && ENV['AZURE_OPENAI_DEPLOYMENT_NAME']
  puts "Error: Please set the following environment variables in a .env file:"
  puts "  AZURE_OPENAI_API_KEY=your_api_key"
  puts "  AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com"
  puts "  AZURE_OPENAI_DEPLOYMENT_NAME=your_deployment_name"
  exit 1
end

# Configure the AI assistant
puts "Configuring ChefAiAssistant..."
ChefAiAssistant.configure do |config|
  config.api_key = ENV['AZURE_OPENAI_API_KEY']
  config.api_version = ENV['AZURE_OPENAI_API_VERSION'] || '2023-05-15'
  config.azure_endpoint = ENV['AZURE_OPENAI_ENDPOINT']
  config.deployment_name = ENV['AZURE_OPENAI_DEPLOYMENT_NAME']
end

# Check command line arguments
if ARGV.empty?
  puts "Usage: #{$0} ai [ask] [question]"
  puts "Example: #{$0} ai ask \"How do I write a Chef recipe?\""
  exit 1
end

# Handle commands directly
command = ARGV[0]
if command == "ai"
  # Create an instance of the AI command
  ai_command = ChefAiAssistant::Commands::Ai.new
  
  # Run the AI command with the remaining arguments
  exit_code = ai_command.run(ARGV[1..-1])
  exit(exit_code || 0)
else
  puts "Unknown command: #{command}"
  puts "Available commands: ai"
  exit 1
end