# frozen_string_literal: true

require 'optparse'
require 'tty-spinner'
require 'tty-prompt'
require 'rainbow'

module ChefAiAssistant
  module Commands
    class Ai
      class CommandGenerator < ChefAiAssistant::Command::Base
        def setup_command
          @name = 'command'
          @description = 'Generate Chef commands from natural language descriptions'
          @banner = 'Usage: chef ai command DESCRIPTION [options]'
          @options = {
            '--help, -h' => 'Show this message',
            '--temperature TEMP' => 'Set the response creativity (0.0-2.0)',
            '--verbose, -v' => 'Show detailed response information'
          }
          @verbose = false
          @temperature = 0.3 # Lower temperature for more deterministic command generation

          # Load the system prompt using the template renderer
          load_system_prompt(nil, 'command')
        end

        def run(args = [])
          if args.empty? || args.include?('--help') || args.include?('-h')
            help
            return 0
          end

          # Handle version flag
          if args.include?('--version') || args.include?('-v')
            puts "Chef AI Assistant version #{ChefAiAssistant::VERSION}"
            return 0
          end

          # Parse options
          remaining_args = parse_options(args)

          # Join the remaining args to form the command description
          command_description = remaining_args.join(' ')
          if command_description.empty?
            prompt = TTY::Prompt.new
            prompt.error('Please provide a description of the command you want to generate')
            help
            return 1
          end

          # Process the command description
          process_command_description(command_description)

          0
        end

        def parse_options(args)
          parser = OptionParser.new do |opts|
            opts.banner = @banner

            opts.on('-h', '--help', 'Show this message') do
              help
              exit 0
            end

            opts.on('--temperature TEMP', Float, 'Set the response creativity (0.0-2.0)') do |temp|
              @temperature = temp
              @temperature = 0.0 if @temperature.negative?
              @temperature = 2.0 if @temperature > 2.0
            end

            opts.on('-v', '--verbose', 'Show detailed response information') do
              @verbose = true
            end
          end

          begin
            parser.order!(args)
            args
          rescue OptionParser::InvalidOption => e
            puts "Error: #{e.message}"
            help
            exit 1
          end
        end

        def process_command_description(description)
          client = ChefAiAssistant.openai_client
          prompt = TTY::Prompt.new

          prompt.say("🔍 #{Rainbow('Processing:').bright.yellow.bold}")
          prompt.say("  \"#{Rainbow(description).bright.white}\"")

          spinner = TTY::Spinner.new("[:spinner] #{Rainbow('Generating command...').bright.cyan}", format: :dots)
          spinner.auto_spin

          # Create messages array with system and user prompts
          messages = [
            { role: 'system', content: @system_prompt }
          ]

          # Add strong boundaries for command generation
          if ChefAiAssistant.respond_to?(:integration_context) && ChefAiAssistant.integration_context
            # Get the parent gem name
            parent_gem = ChefAiAssistant.integration_context.parent_gem_name

            # Create a strong enforcement message for command generation
            enforcement_message =
              "CRITICAL INSTRUCTION: You are integrated with #{parent_gem} and must ONLY generate commands for #{parent_gem}. " \
              "If the user asks for commands related to another Chef tool that is not directly related to #{parent_gem}, " \
              "respond with: \"I'm currently integrated with #{parent_gem} and can only generate #{parent_gem}-specific commands. " \
              'For commands related to [REQUESTED_TOOL], please use the `[REQUESTED_TOOL] ai command` command instead."'

            messages << { role: 'system', content: enforcement_message }
          end

          # Add the user's command request
          messages << { role: 'user', content: "I need the Chef command to: #{description}" }

          # Send the request to the AI
          response = client.chat(nil, {
                                   messages: messages,
                                   temperature: @temperature
                                 })

          spinner.stop

          # Extract and display the response
          content = response.dig('choices', 0, 'message', 'content')

          if content
            process_and_display_command(content, prompt)

            if @verbose
              puts "\n#{Rainbow('Response Details:').bright.blue.bold}"
              puts Rainbow("- Model: #{response['model']}").cyan
              puts Rainbow("- Finish reason: #{response.dig('choices', 0, 'finish_reason')}").cyan
              puts Rainbow("- Prompt tokens: #{response.dig('usage', 'prompt_tokens')}").cyan
              puts Rainbow("- Completion tokens: #{response.dig('usage', 'completion_tokens')}").cyan
              puts Rainbow("- Total tokens: #{response.dig('usage', 'total_tokens')}").cyan
            end
          else
            puts Rainbow('Error: Failed to get a response from the AI assistant').red.bold
          end
        rescue StandardError => e
          spinner&.error('(✗)')
          TTY::Prompt.new
          puts Rainbow("Error: #{e.message}").red.bold
          puts Rainbow(e.backtrace.join("\n")).red if @verbose
        end

        private

        def process_and_display_command(content, prompt)
          # Extract command(s) from the content
          # This simple regex looks for code blocks or commands that look like they start with chef, knife, etc.
          commands = extract_commands(content)

          if commands.empty?
            # If no command was detected, show the full content
            prompt.say("\n🤖 #{Rainbow('AI Response:').bright.blue.bold}")

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
            puts colored_content
            return
          end

          # Display the explanation and commands
          prompt.say("\n🤖 #{Rainbow('Chef Command Generator:').bright.blue.bold}")

          # Display the content, removing any ```bash or ```shell markers for cleaner output
          clean_content = content.gsub(/```(?:bash|shell)\n?/, '').gsub(/```\n?/, '')

          # Process content to add colors
          colored_content = # Code snippets in green
            clean_content.gsub(/`([^`]+)`/) do
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
          puts colored_content

          # For a single command, use it directly without confirmation
          if commands.length == 1
            selected_command = commands[0]
            command_to_run = true
          elsif commands.length > 1
            # If multiple commands were found, let the user choose which one to use
            prompt.say("\n#{Rainbow('Available commands:').bright.yellow.bold}")
            commands.each_with_index do |cmd, idx|
              prompt.say("#{Rainbow(idx + 1).cyan}. #{Rainbow(cmd).bright.white}")
            end

            selection = prompt.ask('Enter number of command to use (or 0 to skip): ', convert: :int) do |q|
              q.in "0-#{commands.length}"
              q.default 0
            end

            if selection.positive?
              command_to_run = true
              selected_command = commands[selection - 1]
            else
              command_to_run = false
            end
          else
            command_to_run = false
          end

          return unless command_to_run && selected_command

          # Prompt for any missing values using <PLACEHOLDER> format
          command = replace_placeholders(selected_command, prompt)

          # Display a clear box around the command for better visibility
          line = Rainbow('=' * [command.length + 8, 60].max).cyan
          prompt.say("\n#{line}")
          prompt.say("##  #{Rainbow('GENERATED CHEF COMMAND').green.bold}  ##")
          prompt.say(line.to_s)
          # Make the command stand out
          prompt.say("\n    #{Rainbow(command).bright.white.bold}\n")
          prompt.say(line.to_s)

          # Information about copying
          prompt.say("\n#{Rainbow('✓ Just copy and paste this command into your terminal to use it.').green.bold}")
        end

        def extract_commands(content)
          commands = []

          # First try to extract commands from code blocks
          content.scan(/```(?:bash|shell)?\n(.*?)```/m) { |match| commands.concat(extract_command_lines(match[0])) }

          # If no commands found in code blocks, try to find command lines in the text
          commands.concat(extract_command_lines(content)) if commands.empty?

          commands.uniq
        end

        def extract_command_lines(text)
          command_lines = []

          # Look for lines that appear to be Chef commands
          chef_command_patterns = [
            /^\s*(chef\s+\w+.*)/,
            /^\s*(knife\s+\w+.*)/,
            /^\s*(inspec\s+\w+.*)/,
            /^\s*(berkshelf\s+\w+.*)/,
            /^\s*(berks\s+\w+.*)/,
            /^\s*(kitchen\s+\w+.*)/,
            /^\s*(foodcritic\s+\w+.*)/,
            /^\s*(ohai\s+.*)/,
            /^\s*(\$\s*(?:chef|knife|inspec|berkshelf|berks|kitchen|foodcritic|ohai)\s+\w+.*)/
          ]

          text.each_line do |line|
            chef_command_patterns.each do |pattern|
              next unless line =~ pattern

              # Remove $ prompt if present
              command = ::Regexp.last_match(1).gsub(/^\$\s*/, '')
              command_lines << command.strip
            end
          end

          command_lines
        end

        def replace_placeholders(command, prompt)
          # Look for placeholders like <NODE_NAME> or <PATH>
          placeholders = command.scan(/<([A-Z_]+)>/)

          # Replace each placeholder with user input
          placeholders.each do |placeholder|
            name = placeholder[0]
            value = prompt.ask("Enter value for #{name}:")
            command.gsub!(/<#{name}>/, value) if value
          end

          command
        end
      end
    end
  end
end
