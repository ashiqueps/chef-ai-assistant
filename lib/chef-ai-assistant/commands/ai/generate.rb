# frozen_string_literal: true

require 'optparse'
require 'tty-spinner'
require 'tty-prompt'
require 'rainbow'
require 'fileutils'

module ChefAiAssistant
  module Commands
    class Ai
      class Generator < ChefAiAssistant::Command::Base
        def setup_command
          @name = 'generate'
          @description = 'Generate Chef ecosystem files from natural language descriptions'
          @banner = 'Usage: chef ai generate DESCRIPTION [options]'
          @options = {
            '--help, -h' => 'Show this message',
            '--output PATH, -o PATH' => 'Specify output directory (default: current directory)',
            '--temperature TEMP' => 'Set the response creativity (0.0-2.0)',
            '--verbose, -v' => 'Show detailed response information'
          }
          @verbose = false
          @temperature = 0.7 # Slightly higher temperature for more creative generations
          @output_dir = Dir.pwd # Default to current directory
          @system_prompt = 'You are a Chef ecosystem expert. Your task is to generate Chef-related files and directories based on natural language descriptions. This includes cookbooks, recipes, attributes, resources, templates, tests, and any other files used in the Chef ecosystem. Always ensure the generated files follow Chef best practices and conventions. Ask clarifying questions when essential information is missing. Structure your response in JSON format with filename as the key and file content as the value. For directories that need to be created, use "/" at the end of the path. Do not include any additional text outside the JSON structure.'
        end

        def run(args = [])
          if args.empty? || args.include?('--help') || args.include?('-h')
            help
            return 0
          end

          # Parse options
          remaining_args = parse_options(args)

          # Join the remaining args to form the generation description
          generation_description = remaining_args.join(' ')
          if generation_description.empty?
            prompt = TTY::Prompt.new
            prompt.error('Please provide a description of what you want to generate')
            help
            return 1
          end

          # Process the generation description
          process_generation_description(generation_description)

          0
        end

        def parse_options(args)
          parser = OptionParser.new do |opts|
            opts.banner = @banner

            opts.on('-h', '--help', 'Show this message') do
              help
              exit 0
            end

            opts.on('-o', '--output PATH', 'Specify output directory (default: current directory)') do |path|
              @output_dir = File.expand_path(path)
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

        def process_generation_description(description)
          client = ChefAiAssistant.openai_client
          prompt = TTY::Prompt.new
          
          prompt.say("🔍 #{Rainbow('Processing:').bright.yellow.bold}")
          prompt.say("  \"#{Rainbow(description).bright.white}\"")
          prompt.say("  #{Rainbow("Output directory:").bright.yellow} #{Rainbow(@output_dir).bright.white}")

          spinner = TTY::Spinner.new("[:spinner] #{Rainbow('Generating Chef files...').bright.cyan}", format: :dots)
          spinner.auto_spin

          # Create messages array with system and user prompts
          messages = [
            { role: 'system', content: @system_prompt },
            { role: 'user', content: "I need to generate Chef files for: #{description}. Please create all necessary files and directories following Chef best practices." }
          ]

          # Send the request to the AI
          response = client.chat(nil, {
            messages: messages,
            temperature: @temperature
          })

          spinner.stop

          # Extract and display the response
          content = response.dig('choices', 0, 'message', 'content')

          if content
            process_and_generate_files(content, prompt)

            if @verbose
              puts "\n" + Rainbow('Response Details:').bright.blue.bold
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
          prompt = TTY::Prompt.new
          puts Rainbow("Error: #{e.message}").red.bold
          puts Rainbow(e.backtrace.join("\n")).red if @verbose
        end

        private

        def process_and_generate_files(content, prompt)
          # Try to extract JSON from the content
          json_content = extract_json(content)
          
          if json_content.nil?
            prompt.error("Failed to parse AI response as JSON")
            prompt.say("\n🤖 #{Rainbow('AI Response:').bright.blue.bold}")
            puts content
            return
          end
          
          # Get confirmation before generating files
          prompt.say("\n🤖 #{Rainbow('Chef File Generator:').bright.blue.bold}")
          prompt.say("#{Rainbow('Files to be generated:').bright.yellow}")
          
          # Display the files that will be generated
          json_content.each do |path, _content|
            is_dir = path.end_with?('/')
            icon = is_dir ? '📁' : '📄'
            prompt.say("  #{icon} #{Rainbow(path).bright.white}")
          end
          
          # Ask for confirmation
          unless prompt.yes?("\n#{Rainbow('Do you want to generate these files?').bright.yellow}")
            prompt.warn("File generation cancelled")
            return
          end
          
          # Ensure the output directory exists
          FileUtils.mkdir_p(@output_dir) unless Dir.exist?(@output_dir)
          
          # Generate the files
          success_count = 0
          json_content.each do |path, content|
            full_path = File.join(@output_dir, path)
            
            # If path ends with /, it's a directory
            if path.end_with?('/')
              if !Dir.exist?(full_path) && FileUtils.mkdir_p(full_path)
                success_count += 1
                prompt.say("  #{Rainbow('✓').green} Created directory #{Rainbow(path).bright.white}")
              end
            else
              # Ensure parent directory exists
              parent_dir = File.dirname(full_path)
              FileUtils.mkdir_p(parent_dir) unless Dir.exist?(parent_dir)
              
              # Write the file
              begin
                File.write(full_path, content)
                success_count += 1
                prompt.say("  #{Rainbow('✓').green} Generated #{Rainbow(path).bright.white}")
              rescue StandardError => e
                prompt.error("Failed to write #{path}: #{e.message}")
              end
            end
          end
          
          # Summary
          total_count = json_content.size
          prompt.say("\n#{Rainbow('Generation Summary:').bright.blue.bold}")
          prompt.say("#{Rainbow("#{success_count} of #{total_count} files/directories created successfully").green}")
          prompt.say("#{Rainbow('Location:').bright.yellow} #{Rainbow(@output_dir).bright.white}")
        end
        
        def extract_json(content)
          # First try to extract JSON from code blocks
          json_match = content.match(/```(?:json)?\s*(\{.*?\})```/m)
          json_str = json_match ? json_match[1] : content
          
          # Try to parse JSON
          begin
            return JSON.parse(json_str)
          rescue JSON::ParserError => e
            # If the first attempt fails, try to find and parse JSON without code blocks
            begin
              # Look for content that looks like JSON
              if content =~ /\{.*\}/m
                json_block = content.match(/(\{.*\})/m)[1]
                return JSON.parse(json_block)
              end
            rescue StandardError
              return nil
            end
          end
        end
      end
    end
  end
end
