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

          # Read the system prompt from the file
          system_prompt_path = File.join(File.dirname(__FILE__), 'system_prompt.txt')
          base_system_prompt = File.exist?(system_prompt_path) ? File.read(system_prompt_path) : 'You are a Chef expert AI assistant.'

          # Add ask-specific instructions
          @system_prompt = base_system_prompt + "\n\n" \
                           'Your current task is to answer questions related to Chef ecosystem components, tools, ' \
                           'best practices, and general usage. Provide clear, concise, and accurate information ' \
                           'that helps the user understand Chef concepts and solve problems.'
        end

        def run(args = [])
          if args.empty? || args.include?('--help') || args.include?('-h')
            help
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
          messages = [
            { role: 'system', content: @system_prompt },
            { role: 'user', content: question }
          ]

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

          # Extract and display the response
          content = response.dig('choices', 0, 'message', 'content')

          if content
            prompt.say("\n🤖 #{Rainbow('AI Assistant:').bright.blue.bold}")

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
          else
            puts Rainbow('Error: Failed to get a response from the AI assistant').red.bold
          end
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
