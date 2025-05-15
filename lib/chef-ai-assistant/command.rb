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
        # Ensure configuration exists
        begin
          # Ensure ChefAiAssistant module is loaded
          require 'chef-ai-assistant' unless defined?(ChefAiAssistant)

          # Initialize configuration if needed
          ChefAiAssistant.configuration ||= ChefAiAssistant::Configuration.new
        rescue StandardError => e
          puts "Warning: Failed to initialize configuration: #{e.message}" if ENV['DEBUG']
        end

        # Check if strict context mode is enabled (with safeguards)
        begin
          strict_context = if ChefAiAssistant.respond_to?(:configuration) && ChefAiAssistant.configuration
                             if ChefAiAssistant.configuration.respond_to?(:strict_context_aware)
                               ChefAiAssistant.configuration.strict_context_aware.nil? ||
                                 ChefAiAssistant.configuration.strict_context_aware
                             else
                               true # Default to strict if not set
                             end
                           else
                             true # Default to strict if configuration isn't available
                           end
        rescue StandardError => e
          strict_context = true # Default to strict in case of errors
          puts "Warning: Error determining context mode: #{e.message}" if ENV['DEBUG']
        end

        # Get integration context with safe fallbacks
        begin
          integration_context = if ChefAiAssistant.respond_to?(:integration_context)
                                  ChefAiAssistant.integration_context
                                else
                                  ChefAiAssistant::IntegrationContext.new
                                end
        rescue StandardError => e
          # Create a minimal context if we can't get it from the module
          begin
            integration_context = ChefAiAssistant::IntegrationContext.new
          rescue StandardError => e2
            integration_context = nil
            puts "Warning: Failed to create integration context: #{e2.message}" if ENV['DEBUG']
          end
          puts "Warning: Error getting integration context: #{e.message}" if ENV['DEBUG']
        end

        # Prepare template variables with safe defaults
        variables = {
          strict_context: strict_context,
          integration_context: integration_context,
          command_type: command_type || @name || 'general'
        }

        # Use the prompt renderer to generate the system prompt
        prompt_template = command_type || @name || 'base'

        begin
          # First try to load the renderer
          renderer = ChefAiAssistant::Utils::PromptRenderer.new
        rescue StandardError => e
          # If renderer fails to load, use a simple fallback
          puts "Warning: Failed to create prompt renderer: #{e.message}" if ENV['DEBUG']
          return get_fallback_prompt(variables)
        end

        begin
          # Try primary template
          @system_prompt = renderer.render(prompt_template, variables)
        rescue ArgumentError => e
          # If the specific template doesn't exist, fall back to base
          if prompt_template != 'base'
            begin
              @system_prompt = renderer.render('base', variables)
            rescue StandardError => base_error
              # If even base template fails, use a simple fallback
              @system_prompt = get_fallback_prompt(variables)
              if ENV['DEBUG']
                puts "Warning: Base template error: #{base_error.message}\n#{base_error.backtrace.join("\n")}"
              end
            end
          else
            # If base template was requested but failed, use a simple fallback
            @system_prompt = get_fallback_prompt(variables)
          end
          puts "Warning: #{e.message}" if ENV['DEBUG']
        rescue StandardError => e
          # Catch any other errors and provide a simple fallback
          @system_prompt = get_fallback_prompt(variables)
          puts "Error rendering template: #{e.message}\n#{e.backtrace.join("\n")}" if ENV['DEBUG']
        end

        @system_prompt
      end

      private

      # Generate a fallback prompt when everything else fails
      def get_fallback_prompt(variables)
        gem_name = if variables[:integration_context].respond_to?(:parent_gem_name)
                     variables[:integration_context].parent_gem_name
                   elsif variables[:integration_context].is_a?(String)
                     variables[:integration_context]
                   else
                     'chef'
                   end

        command_type = variables[:command_type] || 'general'

        # Create a basic but helpful prompt
        prompt = "You are a Chef expert AI assistant focusing on #{gem_name}. "
        prompt += "You specialize in helping with #{command_type} tasks. "
        prompt += 'Provide clear, concise answers to Chef-related questions.'

        # Add context awareness information if available
        if variables[:strict_context] == false
          prompt += ' You can answer questions about the entire Chef ecosystem.'
        elsif gem_name != 'chef'
          prompt += " Focus on #{gem_name}-specific functionality."
        end

        prompt
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

      # Ensure credentials exist before running commands with better error handling
      def ensure_credentials_exist
        # First check if credentials exist
        begin
          return true if ChefAiAssistant::CredentialsManager.credentials_exist?
        rescue StandardError => e
          # Log the error but continue with the warning process
          puts "Error checking credentials: #{e.message}" if ENV['DEBUG']
        end

        # Determine the command prefix for setup instructions based on integration context
        cmd_prefix = 'chef'
        begin
          if ChefAiAssistant.respond_to?(:integration_context) && ChefAiAssistant.integration_context
            cmd_prefix = ChefAiAssistant.integration_context.parent_gem_name
          end
        rescue StandardError => e
          # If there's an error determining the integration context, use default
          puts "Error determining command prefix: #{e.message}" if ENV['DEBUG']
        end

        # If we reach here, credentials don't exist - try to display a helpful message
        begin
          # Only use TTY if in terminal
          if $stdout.isatty && !ENV['CI'] && !ENV['TEST']
            require 'tty-prompt'
            prompt = TTY::Prompt.new
            prompt.error('Azure OpenAI credentials not found')
            prompt.say("Please run '#{cmd_prefix} ai setup' to configure your credentials")
          else
            # In non-TTY environment (like CI), use simple puts
            puts 'Error: Azure OpenAI credentials not found'
            puts "Please run '#{cmd_prefix} ai setup' to configure your credentials"
          end
        rescue LoadError => e
          # TTY gem might not be available, fall back to basic output
          puts "Error: Azure OpenAI credentials not found (#{e.message})"
          puts "Please run '#{cmd_prefix} ai setup' to configure your credentials"
        rescue StandardError => e
          # Any other error, still try to show message
          puts "Error: Azure OpenAI credentials not found (#{e.message})"
          puts "Please run '#{cmd_prefix} ai setup' to configure your credentials"
        end

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
        # Try multiple registration methods to support different CLI frameworks

        # Method 1: Chef-style register_subcommand
        if app_class.respond_to?(:register_subcommand)
          app_class.register_subcommand(command_name, description, command_class)
          puts 'Registered AI command using register_subcommand' if ENV['DEBUG']
          return true
        end

        # Method 2: Thor/CLI Kit style commands
        if app_class.respond_to?(:desc) && app_class.respond_to?(:subcommand)
          app_class.desc command_name, description
          app_class.subcommand command_name, command_class
          puts 'Registered AI command using Thor-style subcommand' if ENV['DEBUG']
          return true
        end

        # Method 3: Register with command map
        if app_class.respond_to?(:commands) && app_class.commands.is_a?(Hash)
          app_class.commands[command_name] = command_class.new
          puts 'Registered AI command using commands hash' if ENV['DEBUG']
          return true
        end

        # Method 4: Register through class method
        if app_class.respond_to?(:register)
          app_class.register(command_class, command_name, "#{command_name} [SUBCOMMAND]", description)
          puts 'Registered AI command using register method' if ENV['DEBUG']
          return true
        end

        # Method 5: Create a subcommands namespace (Chef style)
        # Default implementation if the parent class doesn't have a register method
        if app_class.const_defined?(:Subcommands)
          subcommands = app_class.const_get(:Subcommands)
        else
          subcommands = Module.new
          app_class.const_set(:Subcommands, subcommands)
        end

        # Create the command class in the parent's Subcommands namespace
        const_name = command_name.capitalize.gsub(/[-_]([a-z])/) { ::Regexp.last_match(1).upcase }
        subcommand_class = Class.new(command_class)
        subcommands.const_set(const_name, subcommand_class)
        puts 'Registered AI command using subcommands namespace' if ENV['DEBUG']
        true
      rescue StandardError => e
        # Log the error but don't crash
        puts "Warning: Failed standard registration for #{command_name}: #{e.message}" if ENV['DEBUG']
        puts e.backtrace.join("\n") if ENV['DEBUG']

        # Last resort: Monkey patch the class to add our command
        begin
          # Define a method on the app_class to handle the command
          app_class.class_eval do
            define_method(command_name.to_sym) do |*args|
              command_class.new.run(args)
            end
          end
          puts "Added #{command_name} method to #{app_class}" if ENV['DEBUG']
          true
        rescue StandardError => eval_error
          puts "Failed to add method via class_eval: #{eval_error.message}" if ENV['DEBUG']
          false
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
