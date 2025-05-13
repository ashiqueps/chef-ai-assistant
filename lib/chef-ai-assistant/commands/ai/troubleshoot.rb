# frozen_string_literal: true

require 'optparse'
require 'tty-spinner'
require 'tty-prompt'

module ChefAiAssistant
  module Commands
    class Ai
      class Troubleshoot < ChefAiAssistant::Command::Base
        def setup_command
          @name = 'troubleshoot'
          @description = 'Diagnose and troubleshoot Chef-related issues'
          @banner = 'Usage: chef ai troubleshoot [ERROR_MESSAGE or FILE_PATH] [options]'
          @options = {
            '--help, -h' => 'Show this message',
            '--logs PATH' => 'Path to Chef logs to analyze',
            '--config PATH' => 'Path to Chef config to analyze',
            '--temperature TEMP' => 'Set the response creativity (0.0-2.0)',
            '--verbose, -v' => 'Show detailed response information'
          }
          @verbose = false
          @temperature = 0.4
          @system_prompt = 'You are a Chef troubleshooting expert. Your task is to help users diagnose and fix common Chef-related issues. Analyze error messages, log files, or configuration files provided by the user. Provide clear step-by-step solutions when possible. Format your responses for optimal readability in a terminal. Your answers should be practical, actionable, and focus on best practices for Chef.'
        end

        def run(args = [])
          if args.empty? || args.include?('--help') || args.include?('-h')
            help
            return 0
          end

          # Parse options
          options = {}
          remaining_args = parse_options(args, options)

          # Get the error message or file path
          error_or_path = remaining_args.join(' ')
          
          # Check for log path and config path
          log_path = options[:logs]
          config_path = options[:config]

          # Process the troubleshooting request
          process_troubleshooting_request(error_or_path, log_path, config_path)

          0
        end

        def parse_options(args, options = {})
          parser = OptionParser.new do |opts|
            opts.banner = @banner

            opts.on('-h', '--help', 'Show this message') do
              help
              exit 0
            end

            opts.on('--logs PATH', 'Path to Chef logs to analyze') do |path|
              options[:logs] = path
            end

            opts.on('--config PATH', 'Path to Chef config to analyze') do |path|
              options[:config] = path
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

        def process_troubleshooting_request(error_or_path, log_path = nil, config_path = nil)
          client = ChefAiAssistant.openai_client
          prompt = TTY::Prompt.new
          
          prompt.say("🔍 #{prompt.decorate('Analyzing issue:', :bold)}")
          
          # Prepare the content for the AI
          content = prepare_content(error_or_path, log_path, config_path, prompt)
          
          # Early return if no content to analyze
          return if content.empty?

          # Start the spinner
          spinner = TTY::Spinner.new("[:spinner] #{prompt.decorate('Consulting AI assistant...', :cyan)}", format: :dots)
          spinner.auto_spin

          # Create messages array with system and user prompts
          messages = [
            { role: 'system', content: @system_prompt },
            { role: 'user', content: content }
          ]

          # Send the request to the AI
          response = client.chat(nil, {
            messages: messages,
            temperature: @temperature,
            max_tokens: 2500 # Increase max_tokens to get more complete responses
          })

          spinner.stop

          # Extract and display the response
          ai_response = response.dig('choices', 0, 'message', 'content')

          if ai_response
            display_troubleshooting_response(ai_response, prompt)

            if @verbose
              puts "\n" + prompt.decorate('Response Details:', :bold)
              puts "- Model: #{response['model']}"
              puts "- Finish reason: #{response.dig('choices', 0, 'finish_reason')}"
              puts "- Prompt tokens: #{response.dig('usage', 'prompt_tokens')}"
              puts "- Completion tokens: #{response.dig('usage', 'completion_tokens')}"
              puts "- Total tokens: #{response.dig('usage', 'total_tokens')}"
            end
          else
            prompt.error('Failed to get a response from the AI assistant')
          end
        rescue StandardError => e
          spinner&.error('(✗)')
          prompt = TTY::Prompt.new
          prompt.error(e.message.to_s)
          puts e.backtrace if @verbose
        end

        private
        
        def prepare_content(error_or_path, log_path, config_path, prompt)
          content = []
          
          # First check if we're dealing with a file path
          if error_or_path && !error_or_path.empty? && File.exist?(error_or_path)
            begin
              content << "## Error file content:\n"
              file_content = File.read(error_or_path)
              content << file_content
              prompt.say("  #{error_or_path}")
            rescue => e
              prompt.warn("  Could not read file #{error_or_path}: #{e.message}")
            end
          elsif error_or_path && !error_or_path.empty?
            # If not a file, treat as an error message
            content << "## Error message:\n"
            content << error_or_path
            prompt.say("  \"#{error_or_path}\"")
          end
          
          # Add log file content if provided
          if log_path && File.exist?(log_path)
            begin
              log_content = File.read(log_path)
              if !log_content.empty?
                content << "\n## Log file content:\n"
                # For large log files, get only the last 100 lines or so
                if log_content.lines.count > 100
                  log_lines = log_content.lines.last(100)
                  content << "### NOTE: Showing only the last 100 lines of the log file.\n\n"
                  content << log_lines.join
                else
                  content << log_content
                end
                prompt.say("  Log file: #{log_path}")
              else
                prompt.warn("  Log file is empty: #{log_path}")
              end
            rescue => e
              prompt.warn("  Could not read log file #{log_path}: #{e.message}")
            end
          elsif log_path
            prompt.warn("  Log file not found: #{log_path}")
          end
          
          # Add config file content if provided
          if config_path && File.exist?(config_path)
            begin
              config_content = File.read(config_path)
              content << "\n## Configuration file content:\n"
              content << config_content
              prompt.say("  Config file: #{config_path}")
            rescue => e
              prompt.warn("  Could not read config file #{config_path}: #{e.message}")
            end
          elsif config_path
            prompt.warn("  Config file not found: #{config_path}")
          end
          
          if content.empty?
            prompt.error("No content provided for troubleshooting. Please provide an error message or file path.")
          end
          
          content.join("\n")
        end

        def display_troubleshooting_response(response, prompt)
          # Add a title for the diagnosis
          prompt.say("\n🔧 #{prompt.decorate('Troubleshooting Diagnosis:', :bold)}")
          
          # Display the formatted response
          formatted_response = format_response(response)
          puts formatted_response
        end
        
        def format_response(response)
          # Format the response with better separation of sections using TTY::Prompt instead of Rainbow
          prompt = TTY::Prompt.new
          begin
            formatted_lines = []
            
            # Process the response line by line
            response.each_line do |line|
              line = line.chomp
              
              # Handle markdown headings
              if line.start_with?('### ')
                formatted_lines << "\n" + prompt.decorate(line, :magenta, :bold)
              elsif line.start_with?('## ')
                formatted_lines << "\n" + prompt.decorate(line, :magenta, :bold)
              elsif line.start_with?('# ')
                formatted_lines << "\n" + prompt.decorate(line, :magenta, :bold)
              
              # Handle solution steps
              elsif line.match?(/^Step \d+:/)
                formatted_lines << "\n" + prompt.decorate(line, :green, :bold)
              
              # Handle numbered steps
              elsif line.match?(/^\d+\.\s+/)
                formatted_lines << prompt.decorate(line, :green)
              
              # Handle warnings
              elsif line.include?('Warning:')
                formatted_lines << prompt.decorate(line, :yellow, :bold)
              
              # Handle errors
              elsif line.include?('Error:')
                formatted_lines << prompt.decorate(line, :red, :bold)
              
              # Handle solution section
              elsif line == 'Solution:'
                formatted_lines << "\n" + '-' * 40 + "\n" + prompt.decorate(line, :green, :bold)
              
              # Handle summary section
              elsif line == 'Summary:'
                formatted_lines << "\n" + '-' * 40 + "\n" + prompt.decorate(line, :green, :bold)
              
              # Handle horizontal rules
              elsif line == '---'
                formatted_lines << '-' * 40
              
              # Handle everything else
              else
                # Look for bold text (**text**)
                if line.include?('**')
                  line = line.gsub(/\*\*(.*?)\*\*/) { |_| prompt.decorate($1, :bold) }
                end
                
                # Look for italic text (*text*)
                if line.include?('*')
                  line = line.gsub(/\*(.*?)\*/) { |_| prompt.decorate($1, :italic) }
                end
                
                formatted_lines << line
              end
            end
            
            # Process code blocks after handling line-by-line formatting
            formatted_text = formatted_lines.join("\n")
            formatted_text = formatted_text.gsub(/```(?:bash|ruby|sh)?$(.*?)```/m) do |_|
              "\n" + prompt.decorate($1, :cyan)
            end
            
            return formatted_text
            
          rescue => e
            # If any error occurs in formatting, return the original response
            puts "Warning: Error in response formatting: #{e.message}" if @verbose
            return response
          end
        end
      end
    end
  end
end
