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
        if args.empty? || args.first == '--help' || args.first == '-h'
          show_help
          return 0
        end

        if ['--version', '-v'].include?(args.first)
          show_version
          return 0
        end

        subcommand = args.first
        if @subcommands.key?(subcommand)
          @subcommands[subcommand].run(args[1..-1])
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
        puts "\nRun '#{prompt.decorate("chef ai SUBCOMMAND --help", :cyan)}' for more information on a specific subcommand."
      end

      def show_version
        puts "Chef AI Assistant version #{ChefAiAssistant::VERSION}"
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
        register_subcommand('ask', 'Ask the AI assistant a question', ChefAiAssistant::Commands::Ai::Ask)
        register_subcommand('explain', 'Explain Chef-related files or directories', ChefAiAssistant::Commands::Ai::Explain)
        register_subcommand('command', 'Generate Chef commands from descriptions', ChefAiAssistant::Commands::Ai::CommandGenerator)
        register_subcommand('troubleshoot', 'Diagnose and troubleshoot Chef-related issues', ChefAiAssistant::Commands::Ai::Troubleshoot)
        register_subcommand('generate', 'Generate Chef ecosystem files and directories', ChefAiAssistant::Commands::Ai::Generator)
      end

      def register_subcommand(name, _description, klass)
        @subcommands[name] = klass.new
      end

      # Class method to register this command with a parent application
      def self.register_with(app_class)
        ChefAiAssistant::Command::Base.register_subcommand(
          app_class,
          'ai',
          'Chef AI Assistant commands',
          self
        )
      end
    end
  end
end
