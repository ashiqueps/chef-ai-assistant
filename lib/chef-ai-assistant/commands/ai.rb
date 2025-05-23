# frozen_string_literal: true

require 'optparse'
require_relative '../command'

module ChefAiAssistant
  module Commands
    class Ai < ChefAiAssistant::Command::Base
      attr_reader :subcommands

      def initialize
        super
        @subcommands = {}
        load_subcommands
      end

      def setup_command
        @name = 'ai'
        @description = 'Chef AI Assistant commands'
        @banner = 'Usage: chef ai SUBCOMMAND [options]'
        @options = {
          '--help' => 'Show this message',
          '--version' => 'Show Chef AI Assistant version'
        }
      end

      def run(args = [])
        # Handle global help flag
        if args.empty? || args.first == '--help' || args.first == '-h'
          show_help
          return 0
        end

        # Handle global version flag
        if ['--version', '-v'].include?(args.first)
          show_version
          return 0
        end

        subcommand = args.first
        if @subcommands.key?(subcommand)
          # Process subcommand arguments
          subcommand_args = args[1..-1]

          # If the subcommand is followed by help or version flags,
          # we can just call the subcommand directly as our base class should handle it
          @subcommands[subcommand].run(subcommand_args)
        else
          puts "Unknown subcommand: #{subcommand}"
          show_help
          1
        end
      end

      def show_help
        require 'tty-prompt'
        prompt = TTY::Prompt.new

        puts @banner
        puts "\n#{prompt.decorate('Available subcommands:', :bold)}"
        @subcommands.each do |name, cmd|
          puts "  #{prompt.decorate(name, :blue).ljust(17)} #{cmd.description}"
        end
        puts "\n#{prompt.decorate('Options:', :bold)}"
        @options.each do |option, desc|
          puts "  #{prompt.decorate(option, :blue).ljust(17)} #{desc}"
        end

        # Show integration context if available
        if ChefAiAssistant.respond_to?(:integration_context) && ChefAiAssistant.integration_context
          parent_gem = ChefAiAssistant.integration_context.parent_gem_name
          parent_ver = ChefAiAssistant.integration_context.parent_gem_version
          puts "\n#{prompt.decorate('Integration:',
                                    :bold)} Integrated with #{prompt.decorate(parent_gem, :magenta)} v#{parent_ver}"
        end

        # Show command example with correct prefix based on integration context
        cmd_prefix = if ChefAiAssistant.respond_to?(:integration_context) && ChefAiAssistant.integration_context
                       ChefAiAssistant.integration_context.parent_gem_name
                     else
                       'chef'
                     end
        puts "\nRun '#{prompt.decorate("#{cmd_prefix} ai SUBCOMMAND --help",
                                       :cyan)}' for more information on a specific subcommand."
      end

      def show_version
        version_info = "Chef AI Assistant version #{ChefAiAssistant::VERSION}"

        # Add integration context if available
        if ChefAiAssistant.respond_to?(:integration_context) && ChefAiAssistant.integration_context
          version_info += " (integrated with #{ChefAiAssistant.integration_context})"
        end

        puts version_info
      end

      def load_subcommands
        # Load all subcommand files in the commands/ai directory
        dir = File.expand_path('../commands/ai', __dir__)
        if File.directory?(dir)
          Dir.glob(File.join(dir, '*.rb')).sort.each do |file|
            require file
          end
        end

        # Register built-in subcommands
        register_subcommand('setup', 'Set up AI Assistant credentials', ChefAiAssistant::Commands::Ai::Setup)
        register_subcommand('ask', 'Ask the AI assistant a question', ChefAiAssistant::Commands::Ai::Ask)
        register_subcommand('explain', 'Explain Chef-related files or directories',
                            ChefAiAssistant::Commands::Ai::Explain)
        register_subcommand('command', 'Generate Chef commands from descriptions',
                            ChefAiAssistant::Commands::Ai::CommandGenerator)
        register_subcommand('troubleshoot', 'Diagnose and troubleshoot Chef-related issues',
                            ChefAiAssistant::Commands::Ai::Troubleshoot)
        register_subcommand('generate', 'Generate Chef ecosystem files and directories',
                            ChefAiAssistant::Commands::Ai::Generator)
        register_subcommand('migrate', 'Assist with migrations between Chef versions',
                            ChefAiAssistant::Commands::Ai::Migrator)
      end

      def register_subcommand(name, _description, klass)
        @subcommands[name] = klass.new
      end

      # Class method to register this command with a parent application
      def self.register_with(app_class)
        # Check if the app_class supports the standard Chef CLI pattern
        ChefAiAssistant::Command::Base.register_subcommand(
          app_class,
          'ai',
          'Chef AI Assistant commands',
          self
        )
      rescue NoMethodError => e
        # If standard registration fails, try alternative approaches
        if app_class.respond_to?(:commands)
          # For command map style CLIs (like Thor)
          begin
            app_class.commands['ai'] = new
            puts 'Registered AI command using command map style' if ENV['DEBUG']
          rescue StandardError => cmd_error
            puts "Failed to register via commands map: #{cmd_error.message}" if ENV['DEBUG']
          end
        elsif app_class.respond_to?(:register)
          # For register style CLIs
          begin
            app_class.register(self, 'ai', 'ai [SUBCOMMAND]', 'Chef AI Assistant commands')
            puts 'Registered AI command using register style' if ENV['DEBUG']
          rescue StandardError => reg_error
            puts "Failed to register via register method: #{reg_error.message}" if ENV['DEBUG']
          end
        elsif app_class.respond_to?(:define_command)
          # For APIs that use define_command
          begin
            app_class.define_command(:ai, self)
            puts 'Registered AI command using define_command style' if ENV['DEBUG']
          rescue StandardError => def_error
            puts "Failed to register via define_command: #{def_error.message}" if ENV['DEBUG']
          end
        else
          # Last resort - monkey patch the class to add our command
          puts 'Warning: Could not find standard registration method, attempting manual registration' if ENV['DEBUG']
          begin
            # Define a method on the app_class to handle 'ai' commands
            app_class.class_eval do
              define_method(:ai) do |*args|
                ChefAiAssistant::Commands::Ai.new.run(args)
              end
            end
            puts "Added ai method to #{app_class.name}" if ENV['DEBUG']
          rescue StandardError => eval_error
            puts "Failed to register via class_eval: #{eval_error.message}" if ENV['DEBUG']
            raise e # Re-raise original error if all approaches fail
          end
        end
      end
    end
  end
end
