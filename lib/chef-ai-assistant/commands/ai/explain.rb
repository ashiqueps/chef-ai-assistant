# frozen_string_literal: true

require 'optparse'
require 'tty-spinner'
require 'tty-prompt'
require 'pathname'

module ChefAiAssistant
  module Commands
    class Ai
      class Explain < ChefAiAssistant::Command::Base
        def setup_command
          @name = 'explain'
          @description = 'Explain Chef-related files or directories'
          @banner = 'Usage: chef ai explain PATH [options]'
          @options = {
            '--help, -h' => 'Show this message',
            '--temperature TEMP' => 'Set the response creativity (0.0-2.0)',
            '--verbose, -v' => 'Show detailed response information'
          }
          @verbose = false
          @temperature = 0.7
          @system_prompt = 'You are a Chef expert AI assistant. Your task is to explain the purpose and functionality of Chef-related files or directories. Focus only on files related to Chef\'s ecosystem (like cookbooks, recipes, attributes, resources, etc.). For non-Chef related files, indicate they are outside of Chef\'s ecosystem. Be concise but thorough in your explanations. Format your responses for optimal readability in a terminal. Use concise language, clear formatting with line breaks where appropriate, and avoid overly long paragraphs. For code examples, ensure they are properly formatted for CLI display.'
        end

        def run(args = [])
          if args.empty? || args.include?('--help') || args.include?('-h')
            help
            return 0
          end

          # Parse options
          remaining_args = parse_options(args)

          # The remaining args should be the path to explain
          path = remaining_args.first
          if path.nil? || path.empty?
            prompt = TTY::Prompt.new
            prompt.error('Please provide a path to a file or directory')
            help
            return 1
          end

          # Process the file or directory
          process_path(path)

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

        def process_path(path)
          client = ChefAiAssistant.openai_client
          prompt = TTY::Prompt.new
          path_obj = Pathname.new(path)
          
          # Check if path exists
          unless path_obj.exist?
            prompt.error("Path does not exist: #{path}")
            return 1
          end

          # Get file content or directory structure
          if path_obj.file?
            content = get_file_content(path_obj)
            # Include the full path for better context
            query = "Explain this Chef file: #{path_obj.basename}\nPath: #{path_obj}\n\nContent:\n#{content}"
          else
            dir_structure = get_directory_structure(path_obj)
            # Include the full path and a note about the hierarchical structure
            query = "Explain this Chef directory structure: #{path_obj.basename}\nPath: #{path_obj}\n\nHierarchical Structure (indentation shows nesting):\n#{dir_structure}"
          end

          prompt.say("💼 #{prompt.decorate('Analyzing:', :bold)}")
          prompt.say("  #{path}")

          spinner = TTY::Spinner.new("[:spinner] #{prompt.decorate('Consulting AI assistant...', :cyan)}", format: :dots)
          spinner.auto_spin

          # Create messages array with system and user prompts
          messages = [
            { role: 'system', content: @system_prompt },
            { role: 'user', content: query }
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
            prompt.say("\n🤖 #{prompt.decorate('AI Explanation:', :bold)}")
            puts "#{content}\n"

            if @verbose
              puts prompt.decorate('Response Details:', :bold)
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

        def get_file_content(path_obj)
          # Only read the file if it's a text file
          if is_text_file?(path_obj)
            # Read up to 4000 characters to avoid overloading the AI
            content = File.read(path_obj.to_s, encoding: 'utf-8')[0..4000]
            content += "\n...(content truncated for length)..." if File.size(path_obj.to_s) > 4000
            content
          else
            "(Binary file)"
          end
        rescue => e
          "(Error reading file: #{e.message})"
        end

        def get_directory_structure(path_obj)
          # Build a hierarchical directory structure
          # We'll use a hash to represent the tree structure
          tree = {}
          max_entries = 100 # Increase max entries to capture more files
          
          # Get all files and directories, including hidden ones
          all_entries = Dir.glob("#{path_obj}/**/*", File::FNM_DOTMATCH)
          # Skip . and .. entries
          all_entries.reject! { |e| File.basename(e) == '.' || File.basename(e) == '..' }
          # Limit to max_entries
          entries = all_entries[0...max_entries]
          
          # Sort entries: directories first, then files, alphabetically
          entries.sort_by! do |entry|
            [File.directory?(entry) ? 0 : 1, entry.downcase]
          end
          
          # Build a string representation of the directory structure with proper indentation
          structure = []
          entries.each do |entry|
            # Get the relative path from the base directory
            relative_path = Pathname.new(entry).relative_path_from(path_obj).to_s
            components = relative_path.split(File::SEPARATOR)
            
            # Calculate indentation based on depth
            indent = "  " * (components.length - 1)
            
            # Add entry to the tree with proper formatting
            is_dir = File.directory?(entry)
            basename = File.basename(entry)
            entry_str = "#{indent}#{basename}#{is_dir ? '/' : ''}"
            structure << entry_str
          end
          
          # Add truncation notice if there are more entries
          if all_entries.count > max_entries
            structure << "\n...(directory listing truncated, showing #{max_entries} of #{all_entries.count} entries)..."
          end
          
          structure.join("\n")
        end

        def is_text_file?(path_obj)
          # Simple check to see if a file is likely a text file
          return false unless path_obj.file?
          
          begin
            # Read the first 1024 bytes and check if it's valid UTF-8
            # We don't actually need to use the sample, just check if it's valid UTF-8
            File.read(path_obj.to_s, 1024, encoding: 'utf-8')
            return true
          rescue
            return false
          end
        end
      end
    end
  end
end
