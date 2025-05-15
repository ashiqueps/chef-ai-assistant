# frozen_string_literal: true

require 'optparse'
require 'tty-spinner'
require 'tty-prompt'
require 'rainbow'

module ChefAiAssistant
  module Commands
    class Ai
      class Ask < ChefAiAssistant::Command::Base
        def setup_command
          @name = 'ask'
          @description = 'Ask the AI assistant a question'
          @banner = 'Usage: chef ai ask QUESTION [options]'
          @options = {
            '--help, -h' => 'Show this message',
            '--temperature TEMP' => 'Set the response creativity (0.0-2.0)',
            '--system PROMPT' => 'Set a custom system prompt',
            '--verbose, -v' => 'Show detailed response information'
          }
          @verbose = false
          @temperature = 0.7

          # Load the system prompt using the template renderer
          load_system_prompt(nil, 'ask')
        end

        def run(args = [])
          if args.empty? || args.include?('--help') || args.include?('-h')
            help
            return 0
          end

          # Handle version flag
          if args.include?('--version') || args.include?('-v')
            show_version
            return 0
          end

          # Parse options
          remaining_args = parse_options(args)

          # The remaining args should be the question
          question = remaining_args.join(' ')
          if question.empty?
            prompt = TTY::Prompt.new
            prompt.error('Please provide a question')
            help
            return 1
          end

          # Process the question with the AI assistant
          process_question(question)

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

            opts.on('--system PROMPT', String, 'Set a custom system prompt') do |prompt|
              # If provided with a prompt, use it instead of the file
              @system_prompt = prompt
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

        def process_question(question)
          client = ChefAiAssistant.openai_client
          prompt = TTY::Prompt.new

          # Create messages array with system and user prompts
          messages = create_message_array(question)

          prompt.say("💬 #{Rainbow('Question:').bright.yellow.bold}")
          prompt.say("  #{Rainbow(question).bright.white}")

          spinner = TTY::Spinner.new("[:spinner] #{Rainbow('Consulting AI assistant...').bright.cyan}", format: :dots)
          spinner.auto_spin

          # Send the request to the AI
          response = client.chat(nil, {
                                   messages: messages,
                                   temperature: @temperature
                                 })

          spinner.stop

          # Use the shared display_response method
          display_response(response, 'Assistant')
        rescue StandardError => e
          spinner&.error('(✗)')
          TTY::Prompt.new
          puts Rainbow("Error: #{e.message}").red.bold
          puts Rainbow(e.backtrace.join("\n")).red if @verbose
        end
      end
    end
  end
end
