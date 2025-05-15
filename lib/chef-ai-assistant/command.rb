# frozen_string_literal: true

module ChefAiAssistant
  # Base module for all Chef AI Assistant commands
  module Command
    class CommandError < StandardError; end

    class Base
      attr_accessor :name, :description, :options, :banner, :system_prompt

      def initialize
        @options = {}
        setup_command
      end

      # Load the system prompt using the template renderer
      def load_system_prompt(_prompt_path, command_type = nil)
        # No need to require - it's already loaded in chef-ai-assistant.rb

        # Check if strict context mode is enabled
        strict_context = ChefAiAssistant.configuration&.strict_context_aware.nil? || ChefAiAssistant.configuration.strict_context_aware

        # Get integration context
        integration_context = ChefAiAssistant.respond_to?(:integration_context) ? ChefAiAssistant.integration_context : nil

        # Prepare template variables
        variables = {
          strict_context: strict_context,
          integration_context: integration_context,
          command_type: command_type || @name
        }

        # Use the prompt renderer to generate the system prompt
        prompt_template = command_type || @name
        renderer = ChefAiAssistant::Utils::PromptRenderer.new

        begin
          @system_prompt = renderer.render(prompt_template, variables)
        rescue ArgumentError => e
          # If the specific template doesn't exist, fall back to base
          if prompt_template != 'base'
            begin
              @system_prompt = renderer.render('base', variables)
            rescue StandardError => base_error
              # If even base template fails, use a simple fallback
              @system_prompt = "You are a Chef expert AI assistant focusing on #{integration_context&.parent_gem_name || 'chef'}."
              if ENV['DEBUG']
                puts "Warning: Base template error: #{base_error.message}\n#{base_error.backtrace.join("\n")}"
              end
            end
          else
            # If base template was requested but failed, use a simple fallback
            @system_prompt = "You are a Chef expert AI assistant focusing on #{integration_context&.parent_gem_name || 'chef'}."
          end
          puts "Warning: #{e.message}" if ENV['DEBUG']
        rescue StandardError => e
          # Catch any other errors and provide a simple fallback
          @system_prompt = "You are a Chef expert AI assistant focusing on #{integration_context&.parent_gem_name || 'chef'}."
          puts "Error rendering template: #{e.message}\n#{e.backtrace.join("\n")}" if ENV['DEBUG']
        end

        @system_prompt
      end

      def setup_command
        # To be implemented by subclasses
      end

      def parse_options(args)
        # Default implementation that subclasses can override
        args
      end

      def run(args)
        # Handle help flag first (no credentials needed)
        if args.empty? || args.include?('--help') || args.include?('-h')
          help
          return 0
        end

        # Handle version flag next (no credentials needed)
        if args.include?('--version') || args.include?('-v')
          show_version
          return 0
        end

        # Check if credentials exist first, but skip for the setup command
        skip_credential_check = is_a?(ChefAiAssistant::Commands::Ai::Setup) ||
                                args&.first == '--help' || args&.first == '-h' ||
                                args&.first == '--version' || args&.first == '-v'

        # Also skip credential check for subcommands of Ai when help/version are the first args
        if is_a?(ChefAiAssistant::Commands::Ai) && args && args.length > 1
          skip_credential_check ||= ['--help', '-h', '--version', '-v'].include?(args[1])
        end

        ensure_credentials_exist unless skip_credential_check

        # To be implemented by subclasses - override this method but call super first
        # For example:
        # def run(args)
        #   return super(args) if args.empty? || args.include?('--help') || args.include?('--version')
        #   # Your subcommand implementation here
        # end
        raise NotImplementedError, "#{self.class} must implement the run method"
      end

      # Ensure credentials exist before running commands
      def ensure_credentials_exist
        return if ChefAiAssistant::CredentialsManager.credentials_exist?

        # If we reach here, credentials don't exist
        prompt = TTY::Prompt.new
        prompt.error('Azure OpenAI credentials not found')
        prompt.say("Please run 'chef ai setup' to configure your credentials")
        exit 1
      end

      # Create messages array with system and boundary enforcement prompts
      def create_message_array(user_content)
        # Start with the base system prompt
        messages = [{ role: 'system', content: @system_prompt }]

        # Add integration context information if available
        if ChefAiAssistant.respond_to?(:integration_context) && ChefAiAssistant.integration_context
          parent_gem = ChefAiAssistant.integration_context.parent_gem_name

          # Check if strict context mode is enabled
          strict_context = ChefAiAssistant.configuration&.strict_context_aware.nil? || ChefAiAssistant.configuration.strict_context_aware

          # Only add enforcement message in strict context mode
          if strict_context
            enforcement_message =
              "CRITICAL INSTRUCTION: You are integrated with #{parent_gem} and must ONLY answer questions about #{parent_gem}. " \
              "If the user asks about another Chef tool that is not directly related to #{parent_gem}, " \
              "respond with: \"I'm currently integrated with #{parent_gem} and can only assist with #{parent_gem}-specific questions. " \
              'For questions about [REQUESTED_TOOL], please use the `[REQUESTED_TOOL] ai` command instead."'

            messages << { role: 'system', content: enforcement_message }
          end
        end

        # Add the user's content
        messages << { role: 'user', content: user_content }

        messages
      end

      # Process and display AI response with colorized formatting
      def display_response(response, response_type = 'Assistant')
        require 'tty-prompt'
        require 'rainbow'

        prompt = TTY::Prompt.new
        content = response.dig('choices', 0, 'message', 'content')

        if content
          prompt.say("\n🤖 #{Rainbow("AI #{response_type}:").bright.blue.bold}")

          # Process content to add colors
          colored_content = # Code snippets in green
            content.gsub(/`([^`]+)`/) do
              Rainbow(::Regexp.last_match(1)).green
            end
          colored_content = # Headers in yellow
            colored_content.gsub(/^#+ (.+)$/) do
              Rainbow(::Regexp.last_match(0)).yellow.bold
            end
          colored_content = # Bold text in magenta
            colored_content.gsub(/\*\*([^*]+)\*\*/) do
              Rainbow(::Regexp.last_match(1)).magenta.bold
            end
          puts "#{colored_content}\n"

          if @verbose
            puts Rainbow('Response Details:').bright.blue.bold
            puts Rainbow("- Model: #{response['model']}").cyan
            puts Rainbow("- Finish reason: #{response.dig('choices', 0, 'finish_reason')}").cyan
            puts Rainbow("- Prompt tokens: #{response.dig('usage', 'prompt_tokens')}").cyan
            puts Rainbow("- Completion tokens: #{response.dig('usage', 'completion_tokens')}").cyan
            puts Rainbow("- Total tokens: #{response.dig('usage', 'total_tokens')}").cyan
          end

          # Return the content in case the caller needs it
          content
        else
          puts Rainbow('Error: Failed to get a response from the AI assistant').red.bold
          nil
        end
      end

      # Show version information
      def show_version
        puts "Chef AI Assistant version #{ChefAiAssistant::VERSION}"

        # Add integration context if available
        return unless ChefAiAssistant.respond_to?(:integration_context) && ChefAiAssistant.integration_context

        puts "(integrated with #{ChefAiAssistant.integration_context})"
      end

      # Help formatter for commands
      def help
        require 'tty-prompt'
        prompt = TTY::Prompt.new

        puts banner if banner
        puts prompt.decorate('Description:', :bold) + " #{description}" if description

        return if options.empty?

        puts prompt.decorate('Options:', :bold)
        options.each do |option, desc|
          opt_parts = option.split(',').map(&:strip)
          primary_opt = opt_parts.max_by(&:length)
          puts "  #{prompt.decorate(primary_opt, :bright_blue).ljust(22)} #{desc}"
        end
      end

      # Static register method for child classes to register with parent applications
      def self.register_subcommand(app_class, command_name, description, command_class)
        # This method should be implemented by the gem that includes chef-ai-assistant
        # For example, in chef-cli, this would register the 'ai' command
        if app_class.respond_to?(:register_subcommand)
          app_class.register_subcommand(command_name, description, command_class)
        else
          # Default implementation if the parent class doesn't have a register method
          if app_class.const_defined?(:Subcommands)
            subcommands = app_class.const_get(:Subcommands)
          else
            subcommands = Module.new
            app_class.const_set(:Subcommands, subcommands)
          end

          # Create the command class in the parent's Subcommands namespace
          subcommand_class = Class.new(command_class)
          subcommands.const_set(command_name.capitalize, subcommand_class)
        end
      end
    end

    # Utility method to load all commands from a directory
    def self.load_commands(path)
      Dir.glob(File.join(path, '*.rb')).sort.each do |file|
        require file
      end
    end
  end
end
