module ChefAiAssistant
  # Base module for all Chef AI Assistant commands
  module Command
    class CommandError < StandardError; end

    class Base
      attr_accessor :name, :description, :options, :banner

      def initialize
        @options = {}
        setup_command
      end

      def setup_command
        # To be implemented by subclasses
      end

      def parse_options(args)
        # Default implementation that subclasses can override
        args
      end

      def run(args)
        # To be implemented by subclasses
        raise NotImplementedError, "#{self.class} must implement the run method"
      end

      # Help formatter for commands
      def help
        puts banner if banner
        puts "Description: #{description}" if description
        puts "Options:" unless options.empty?
        options.each do |option, desc|
          puts "  #{option.ljust(20)} #{desc}"
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
      Dir.glob(File.join(path, "*.rb")).each do |file|
        require file
      end
    end
  end
end