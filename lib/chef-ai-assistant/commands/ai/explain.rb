# frozen_string_literal: true

require 'optparse'
require 'tty-spinner'
require 'tty-prompt'
require 'pathname'
require 'rainbow'

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

          # Load the system prompt using the template renderer
          load_system_prompt(nil, 'explain')
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

          prompt.say("💼 #{Rainbow('Analyzing:').bright.yellow.bold}")
          prompt.say("  #{Rainbow(path).bright.white}")

          spinner = TTY::Spinner.new("[:spinner] #{Rainbow('Consulting AI assistant...').bright.cyan}", format: :dots)
          spinner.auto_spin

          # Create messages array with system and user prompts
          messages = create_message_array(query)

          # Replace the default enforcement message with explain-specific one if available
          if ChefAiAssistant.respond_to?(:integration_context) && ChefAiAssistant.integration_context
            parent_gem = ChefAiAssistant.integration_context.parent_gem_name

            # Create explain-specific enforcement message
            explain_enforcement_message =
              "CRITICAL INSTRUCTION: You are integrated with #{parent_gem} and must ONLY explain #{parent_gem}-related files. " \
              "If the user asks you to explain files related to another Chef tool that is not directly related to #{parent_gem}, " \
              "respond with: \"I'm currently integrated with #{parent_gem} and can only explain #{parent_gem}-specific files. " \
              'For questions about [REQUESTED_TOOL], please use the `[REQUESTED_TOOL] ai explain` command instead."'

            # Replace the second message (enforcement message) with explain-specific one
            if messages.length >= 2 && messages[1][:role] == 'system'
              messages[1][:content] = explain_enforcement_message
            end
          end

          # Send the request to the AI
          response = client.chat(nil, {
                                   messages: messages,
                                   temperature: @temperature
                                 })

          spinner.stop

          # Use the shared display_response method
          display_response(response, 'Explanation')
        rescue StandardError => e
          spinner&.error('(✗)')
          TTY::Prompt.new
          puts Rainbow("Error: #{e.message}").red.bold
          puts Rainbow(e.backtrace.join("\n")).red if @verbose
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
            '(Binary file)'
          end
        rescue StandardError => e
          "(Error reading file: #{e.message})"
        end

        def get_directory_structure(path_obj)
          # Build a hierarchical directory structure
          max_entries = 100 # Increase max entries to capture more files

          # Get all files and directories, including hidden ones
          all_entries = Dir.glob("#{path_obj}/**/*", File::FNM_DOTMATCH)
          # Skip . and .. entries
          all_entries.reject! { |e| ['.', '..'].include?(File.basename(e)) }
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
            indent = '  ' * (components.length - 1)

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
            true
          rescue StandardError
            false
          end
        end
      end
    end
  end
end
