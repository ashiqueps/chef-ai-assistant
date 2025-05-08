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
        @name = "ai"
        @description = "Chef AI Assistant commands"
        @banner = "Usage: PARENT_COMMAND ai SUBCOMMAND [options]"
        @options = {
          "--help" => "Show this message",
          "--version" => "Show Chef AI Assistant version"
        }
      end

      def run(args = [])
        if args.empty? || args.first == "--help" || args.first == "-h"
          show_help
          return 0
        end

        if args.first == "--version" || args.first == "-v"
          show_version
          return 0
        end

        subcommand = args.first
        if @subcommands.key?(subcommand)
          @subcommands[subcommand].run(args[1..-1])
        else
          puts "Unknown subcommand: #{subcommand}"
          show_help
          return 1
        end
      end

      def show_help
        puts @banner
        puts "\nAvailable subcommands:"
        @subcommands.each do |name, cmd|
          puts "  #{name.ljust(15)} #{cmd.description}"
        end
        puts "\nOptions:"
        @options.each do |option, desc|
          puts "  #{option.ljust(15)} #{desc}"
        end
        puts "\nRun 'PARENT_COMMAND ai SUBCOMMAND --help' for more information on a specific subcommand."
      end

      def show_version
        puts "Chef AI Assistant version #{ChefAiAssistant::VERSION}"
      end

      def load_subcommands
        # Load all subcommand files in the commands/ai directory
        dir = File.expand_path("../commands/ai", __dir__)
        if File.directory?(dir)
          Dir.glob(File.join(dir, "*.rb")).each do |file|
            require file
          end
        end

        # Register built-in subcommands
        register_subcommand("ask", "Ask the AI assistant a question", ChefAiAssistant::Commands::Ai::Ask)
      end

      def register_subcommand(name, description, klass)
        @subcommands[name] = klass.new
      end

      # Class method to register this command with a parent application
      def self.register_with(app_class)
        ChefAiAssistant::Command::Base.register_subcommand(
          app_class,
          "ai",
          "Chef AI Assistant commands",
          self
        )
      end
    end
  end
end