# frozen_string_literal: true

require 'tty-prompt'
require 'fileutils'
require 'json'

module ChefAiAssistant
  module Commands
    class Ai
      class Setup < ChefAiAssistant::Command::Base
        def setup_command
          @name = 'setup'
          @description = 'Set up AI Assistant credentials'
          @banner = 'Usage: chef ai setup [options]'
          @options = {
            '--help, -h' => 'Show this message',
            '--force' => 'Overwrite existing credentials'
          }
        end

        def run(args = [])
          if args.include?('--help') || args.include?('-h')
            help
            return 0
          end

          force = args.include?('--force')

          # Check if credentials file already exists
          creds_file = credentials_file_path
          if File.exist?(creds_file) && !force
            prompt = TTY::Prompt.new
            prompt.warn("Credentials file already exists at #{creds_file}")

            options = [
              { name: 'Update - Keep existing values as defaults', value: :update },
              { name: 'Overwrite - Start with default values', value: :overwrite },
              { name: 'Cancel', value: :cancel }
            ]

            choice = prompt.select('What would you like to do?', options)

            case choice
            when :cancel
              prompt.say('Setup cancelled.')
              return 0
            when :overwrite
              # Continue with default values
            when :update
              # Continue and use existing values as defaults (handled in setup_credentials)
            end
          end

          # Prompt for credentials
          setup_credentials
          0
        end

        private

        def setup_credentials
          prompt = TTY::Prompt.new

          # Banner
          puts prompt.decorate('=== Chef AI Assistant Setup ===', :bold)
          puts 'This will configure your Chef AI Assistant credentials.'
          puts "The credentials will be stored in #{credentials_file_path}"
          puts

          # Load existing credentials if they exist
          existing_creds = {}
          if ChefAiAssistant::CredentialsManager.credentials_exist?
            begin
              existing_creds = ChefAiAssistant::CredentialsManager.load_credentials
              puts prompt.decorate('Current credentials found. Press Enter to keep the current value.', :blue)
            rescue StandardError => e
              puts prompt.decorate("Warning: Error reading existing credentials: #{e.message}", :yellow)
            end
          end

          # Get API endpoint
          default_endpoint = existing_creds['azure_openai_endpoint'] || 'https://api.openai.azure.com'
          endpoint_prompt = if existing_creds['azure_openai_endpoint']
                              "Azure OpenAI API Endpoint: [current: #{existing_creds['azure_openai_endpoint']}]"
                            else
                              'Azure OpenAI API Endpoint:'
                            end
          api_endpoint = prompt.ask(endpoint_prompt, default: default_endpoint)

          # Validate endpoint
          if api_endpoint.to_s.empty?
            puts prompt.decorate('Warning: No API endpoint provided. Using default: https://api.openai.azure.com',
                                 :yellow)
            api_endpoint = 'https://api.openai.azure.com'
          end

          # Ensure endpoint has the correct format
          unless api_endpoint.start_with?('http')
            puts prompt.decorate('Adding https:// prefix to endpoint', :yellow)
            api_endpoint = "https://#{api_endpoint}"
          end

          # Ensure endpoint ends with a slash for consistency
          api_endpoint = "#{api_endpoint}/" unless api_endpoint.end_with?('/')

          # Get API key - show a hint about existing key but not the actual value for security
          key_prompt = if existing_creds['azure_openai_api_key']
                         'Azure OpenAI API Key: [current: ********]'
                       else
                         'Azure OpenAI API Key:'
                       end
          api_key = prompt.mask(key_prompt)
          # If user didn't enter anything, keep the existing key
          if api_key.to_s.empty?
            if existing_creds['azure_openai_api_key']
              api_key = existing_creds['azure_openai_api_key']
              puts prompt.decorate('Using existing API key.', :green)
            else
              puts prompt.decorate(
                'Warning: No API key provided. The AI assistant will not work without a valid API key.', :yellow
              )
              api_key = prompt.mask('Azure OpenAI API Key:') if prompt.yes?('Would you like to provide an API key now?')
            end
          end

          # Get deployment name
          default_deployment = existing_creds['azure_openai_deployment_name'] || ''
          deployment_prompt = if existing_creds['azure_openai_deployment_name']
                                "Azure OpenAI Deployment Name: [current: #{existing_creds['azure_openai_deployment_name']}]"
                              else
                                'Azure OpenAI Deployment Name:'
                              end
          deployment_name = prompt.ask(deployment_prompt, default: default_deployment)

          # Validate deployment name
          if deployment_name.to_s.empty?
            if existing_creds['azure_openai_deployment_name']
              deployment_name = existing_creds['azure_openai_deployment_name']
              puts prompt.decorate('Using existing deployment name.', :green)
            else
              puts prompt.decorate(
                'Warning: No deployment name provided. The AI assistant will not work without a valid deployment name.', :yellow
              )
              if prompt.yes?('Would you like to provide a deployment name now?')
                deployment_name = prompt.ask('Azure OpenAI Deployment Name:')
              end
            end
          end

          # Get API version
          default_api_version = existing_creds['azure_openai_api_version'] || '2023-05-15'
          version_prompt = if existing_creds['azure_openai_api_version']
                             "Azure OpenAI API Version: [current: #{existing_creds['azure_openai_api_version']}]"
                           else
                             'Azure OpenAI API Version:'
                           end
          api_version = prompt.ask(version_prompt, default: default_api_version)

          # Prepare credentials hash
          credentials = {
            'azure_openai_endpoint' => api_endpoint,
            'azure_openai_api_key' => api_key,
            'azure_openai_deployment_name' => deployment_name,
            'azure_openai_api_version' => api_version
          }

          # Show summary
          puts "\n#{prompt.decorate('Summary of credentials to be saved:', :bold)}"
          puts "Endpoint:       #{api_endpoint}"
          puts "API Key:        #{api_key.to_s.empty? ? '(none)' : '********'}"
          puts "Deployment:     #{deployment_name}"
          puts "API Version:    #{api_version}"
          puts

          if prompt.yes?('Save these credentials?', default: true)
            # Save credentials using the CredentialsManager
            ChefAiAssistant::CredentialsManager.save_credentials(credentials)
            prompt.ok("Credentials saved successfully to #{credentials_file_path}")
          else
            prompt.warn('Setup cancelled. No changes were made.')
            1
          end
        end

        def credentials_file_path
          ChefAiAssistant::CredentialsManager.credentials_file_path
        end
      end
    end
  end
end
