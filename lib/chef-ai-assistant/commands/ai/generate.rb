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

          # Load the system prompt using the template renderer
          load_system_prompt(nil, 'generate')
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
          prompt.say("  #{Rainbow('Output directory:').bright.yellow} #{Rainbow(@output_dir).bright.white}")

          # Determine if this is likely a Chef-related request or something else
          is_chef_related = description.downcase.match?(/chef|cookbook|recipe|inspec|habitat|resource|attribute|knife|data bag|role|environment|vault|kitchen|workstation|/)

          # Early exit if request is not Chef-related
          unless is_chef_related
            prompt.say("\n#{Rainbow('Error:').bright.red.bold} #{Rainbow('This request does not appear to be related to Chef.').bright.white}")
            prompt.say(Rainbow('This tool is specifically designed to generate Chef-related files such as cookbooks,').bright.white.to_s)
            prompt.say(Rainbow('recipes, InSpec tests, and other Chef ecosystem components.').bright.white.to_s)
            prompt.say("\n#{Rainbow('Examples of valid requests:').bright.yellow}")
            prompt.say("  - #{Rainbow('Create a cookbook to install and configure Nginx').bright.green}")
            prompt.say("  - #{Rainbow('Generate an InSpec profile to test secure SSH configuration').bright.green}")
            prompt.say("  - #{Rainbow('Write a Chef recipe for managing user accounts').bright.green}")
            return 1
          end

          # Debug info for integration debugging
          if ENV['CHEF_AI_DEBUG'] || @verbose
            puts Rainbow("\nDEBUG: Preparing to generate content").yellow
            if ChefAiAssistant.respond_to?(:integration_context) && ChefAiAssistant.integration_context
              puts "Integration context: #{ChefAiAssistant.integration_context.parent_gem_name}"
            end
            puts "Output directory: #{@output_dir}"
          end

          spinner = TTY::Spinner.new("[:spinner] #{Rainbow('Generating Chef files...').bright.cyan}", format: :dots)
          spinner.auto_spin

          # Add analysis prompt to understand what we're generating
          analysis_prompt = "Before generating the files, briefly explain in 1-2 sentences what you plan to generate and how it will accomplish the user's request. Then provide the JSON response with the file structure."

          # Add reminder about including actual file contents
          content_reminder = 'Remember to include the complete content for ALL files, not just directory entries. For cookbooks, you MUST include at minimum metadata.rb, recipes/default.rb with actual code content.'

          # Create messages array with system and user prompts
          messages = [
            { role: 'system', content: @system_prompt }
          ]

          # Add integration context information if available
          if ChefAiAssistant.respond_to?(:integration_context) && ChefAiAssistant.integration_context
            # Get the parent gem name
            parent_gem = ChefAiAssistant.integration_context.parent_gem_name

            # Create a strong enforcement message
            enforcement_message =
              "CRITICAL INSTRUCTION: You are integrated with #{parent_gem} and must ONLY generate #{parent_gem}-related files. " \
              "If the user asks you to generate files related to another Chef tool that is not directly related to #{parent_gem}, " \
              "respond with: \"I'm currently integrated with #{parent_gem} and can only generate #{parent_gem}-specific files and code. " \
              'For generating [REQUESTED_TOOL] files, please use the `[REQUESTED_TOOL] ai generate` command instead."'

            messages << { role: 'system', content: enforcement_message }
          end

          # Add the user's generation request
          messages << { role: 'user', content: "I need to generate Chef-related files for: #{description}. " \
              'Please create all necessary Chef files and directories following best practices. ' \
              "Respond with an explanation of what you'll generate, followed by the JSON with all required files for a complete implementation.\n\n#{analysis_prompt}\n\n#{content_reminder}" }

          # Send the request to the AI
          response = client.chat(nil, {
                                   messages: messages,
                                   temperature: @temperature
                                 })

          spinner.stop

          prompt.say("\n#{Rainbow('Processing Request:').bright.yellow} #{Rainbow(description).bright.white}")

          # Extract and display the response
          content = response.dig('choices', 0, 'message', 'content')

          if content
            # Debug the content type for possible integration issues
            if ENV['CHEF_AI_DEBUG'] || @verbose
              puts Rainbow("\nDEBUG: Got response, content type: #{content.class.name}, length: #{content.length}").yellow
              puts Rainbow("DEBUG: Content preview: #{content[0..100]}...").yellow
            end
            
            result = process_and_generate_files(content, prompt)
            
            # If process_and_generate_files returned an error hash instead of completing successfully
            if result.is_a?(Hash) && result[:success] == false
              puts Rainbow("Error processing content: #{result[:error]}").red.bold
              return 1
            end

            if @verbose
              puts "\n#{Rainbow('Response Details:').bright.blue.bold}"
              puts Rainbow("- Model: #{response['model']}").cyan
              puts Rainbow("- Finish reason: #{response.dig('choices', 0, 'finish_reason')}").cyan
              puts Rainbow("- Prompt tokens: #{response.dig('usage', 'prompt_tokens')}").cyan
              puts Rainbow("- Completion tokens: #{response.dig('usage', 'completion_tokens')}").cyan
              puts Rainbow("- Total tokens: #{response.dig('usage', 'total_tokens')}").cyan
            end
            
            return 0
          else
            puts Rainbow('Error: Failed to get a response from the AI assistant').red.bold
            return 1
          end
        rescue StandardError => e
          spinner&.error('(✗)')
          prompt = TTY::Prompt.new
          puts Rainbow("Error: #{e.message}").red.bold
          puts Rainbow(e.backtrace.join("\n")).red if @verbose
          return 1
        end

        # Add a public method that can be called directly by integrating gems
        def process_content_directly(content, description = 'Generated content')
          prompt = TTY::Prompt.new
          
          # Add debugging for chef-cli integration
          if @verbose
            puts "DEBUG: Processing content directly"
            puts "DEBUG: Content type: #{content.class.name}"
            puts "DEBUG: Content preview: #{content[0..100]}..."
            if content.is_a?(Hash)
              puts "DEBUG: Top-level keys: #{content.keys.join(', ')}"
            end
          end
          
          # Extract JSON content from response
          json_content = extract_json(content) || manual_json_extraction(content)
          
          # More debugging after extraction
          if @verbose && json_content
            puts "DEBUG: Extracted JSON content"
            puts "DEBUG: JSON content type: #{json_content.class.name}"
            puts "DEBUG: Top-level keys: #{json_content.keys.join(', ')}" if json_content.is_a?(Hash)
          end
          
          # If the JSON has a nested structure (e.g., directories with files), flatten it
          if json_content && json_content.is_a?(Hash)
            # Check if it's already flattened or needs flattening
            needs_flattening = json_content.any? { |_, v| v.is_a?(Hash) }
            
            # Special handling for files nested under "files" key
            if json_content.key?('files') && json_content['files'].is_a?(Hash)
              # Move files up from the "files" key to avoid extra nesting
              files_content = json_content.delete('files')
              json_content.merge!(files_content)
              puts "DEBUG: Removed 'files/' nesting from JSON structure" if @verbose
            end
            
            # Filter out special metadata keys before processing
            json_content.delete('cookbook_name')
            json_content.delete('directories')
            json_content.each_key do |key|
              json_content.delete(key) if key.start_with?('_')
            end
            
            # Additional handling for content keys in hashes
            json_content.each do |key, value|
              if value.is_a?(Hash) && value.key?('content') && value.keys.size == 1
                json_content[key] = value['content'].to_s
                puts "DEBUG: Simplified content hash for #{key}" if @verbose
              end
            end
            
            if needs_flattening
              json_content = flatten_nested_json_structure(json_content)
              puts "DEBUG: Flattened JSON structure for proper file generation" if @verbose
              puts "DEBUG: Final keys: #{json_content.keys.join(', ')}" if @verbose && json_content.is_a?(Hash)
            end
            
            # Process the flattened content
            process_and_generate_files(json_content, prompt)
          else
            # Regular processing if it's not a nested structure or extraction failed
            process_and_generate_files(content, prompt)
          end
        rescue StandardError => e
          prompt = TTY::Prompt.new
          prompt.error("Error processing content: #{e.message}")
          prompt.say("\n🤖 #{Rainbow('Raw Content:').bright.blue.bold}")
          puts content[0..200] + '...' # Show just the beginning to avoid overwhelming output
          puts Rainbow(e.backtrace.join("\n")).red if @verbose
          
          # Return the error for handling by the calling gem
          return { success: false, error: e.message, content: content }
        end

        private

        def process_and_generate_files(content, prompt)
          # Handle nil or empty content
          if content.nil? || content.strip.empty?
            prompt.error('Received empty content from AI')
            return { success: false, error: 'Empty content received from AI' }
          end
          
          # Extract explanation text before JSON
          explanation = ''
          json_start_index = content.index('{')

          explanation = content[0...json_start_index].strip if json_start_index&.positive?

          # Try to extract JSON from the content
          json_content = extract_json(content)

          if json_content.nil?
            # One last attempt - try a manual extraction for simple cases
            json_content = manual_json_extraction(content)

            if json_content.nil?
              prompt.error('Failed to parse AI response as JSON')
              prompt.say("\n🤖 #{Rainbow('AI Response:').bright.blue.bold}")
              puts content
              
              # Debug information to help with integration issues
              if ENV['CHEF_AI_DEBUG'] || @verbose
                puts Rainbow("\nDEBUG: Integration context:").red
                if ChefAiAssistant.respond_to?(:integration_context) && ChefAiAssistant.integration_context
                  puts "Parent gem: #{ChefAiAssistant.integration_context.parent_gem_name}"
                  puts "Version: #{ChefAiAssistant.integration_context.parent_gem_version}"
                else
                  puts "No integration context available"
                end
                puts Rainbow("DEBUG: Raw content type: #{content.class.name}").red
                puts Rainbow("DEBUG: Raw content length: #{content.length}").red
                puts Rainbow("DEBUG: Content preview: #{content[0..100]}...").red
              end
              
              return { success: false, error: 'Failed to parse AI response as JSON', content: content }
            end
          end

          # Flatten nested JSON structure
          json_content = flatten_nested_json_structure(json_content)

          # Display the AI's explanation if available
          unless explanation.empty?
            prompt.say("\n🤖 #{Rainbow('AI Analysis:').bright.blue.bold}")
            puts Rainbow(explanation.gsub(/```json.*$/, '').strip).bright.white
            puts ''
          end

          # Analyze the files to generate a summary
          file_types = {}
          primary_purpose = ''

          # Get file types and guess the primary purpose
          json_content.each_key do |path|
            if path.end_with?('/')
              file_types['Directory'] ||= 0
              file_types['Directory'] += 1
            elsif path.include?('recipe') || path.end_with?('.rb') && path.include?('recipes/')
              file_types['Recipe'] ||= 0
              file_types['Recipe'] += 1
              primary_purpose = 'Chef recipe' if primary_purpose.empty?
            elsif path.end_with?('.cpp') || path.end_with?('.c') || path.end_with?('.h')
              file_types['C/C++ Code'] ||= 0
              file_types['C/C++ Code'] += 1
              primary_purpose = 'C++ code' if primary_purpose.empty? || primary_purpose == 'Chef recipe'
            elsif path.end_with?('.rb')
              file_types['Ruby Code'] ||= 0
              file_types['Ruby Code'] += 1
            elsif path.end_with?('metadata.rb')
              file_types['Cookbook Metadata'] ||= 0
              file_types['Cookbook Metadata'] += 1
            elsif path.include?('test') || path.include?('spec')
              file_types['Test/Spec'] ||= 0
              file_types['Test/Spec'] += 1
            elsif path.end_with?('.md')
              file_types['Documentation'] ||= 0
              file_types['Documentation'] += 1
            else
              ext = File.extname(path)
              type = ext.empty? ? 'Other' : ext[1..-1].upcase
              file_types[type] ||= 0
              file_types[type] += 1
            end
          end

          # If we couldn't determine a primary purpose, make a guess based on file counts
          if primary_purpose.empty?
            if file_types['Recipe']&.positive?
              primary_purpose = 'Chef recipe'
            elsif file_types['Cookbook Metadata']&.positive?
              primary_purpose = 'Chef cookbook'
            else
              most_common_type = file_types.max_by { |_, count| count }
              primary_purpose = "#{most_common_type[0]} files"
            end
          end

          # Check if we have any actual files or just directories
          has_actual_files = json_content.any? { |path, content| !path.end_with?('/') && !content.empty? }

          # Warn if we only have directories and no actual files
          unless has_actual_files
            prompt.warn("\n#{Rainbow('Warning:').bright.red} The generated response only includes directories without actual file content.")
            prompt.warn("This is likely an error in the AI's response. You should try again with a more specific request.")
            return unless prompt.yes?('Do you want to continue anyway?')
          end

          # Display summary and files for confirmation
          prompt.say("\n🤖 #{Rainbow('Chef File Generator:').bright.blue.bold}")
          prompt.say("#{Rainbow('This will generate:').bright.yellow} #{Rainbow(primary_purpose).bright.green}")

          # Show file type summary
          prompt.say(Rainbow('Summary:').bright.yellow.to_s)
          file_types.each do |type, count|
            prompt.say("  - #{Rainbow(count).bright.green} #{Rainbow(type).bright.white} files")
          end

          prompt.say("\n#{Rainbow('Files to be generated:').bright.yellow}")

          # Display the files that will be generated
          json_content.each_key do |path|
            is_dir = path.end_with?('/')
            icon = is_dir ? '📁' : '📄'
            prompt.say("  #{icon} #{Rainbow(path).bright.white}")
          end

          # Ask for confirmation
          unless prompt.yes?("\n#{Rainbow('Do you want to generate these files?').bright.yellow}")
            prompt.warn('File generation cancelled')
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
          prompt.say(Rainbow("#{success_count} of #{total_count} files/directories created successfully").green.to_s)
          prompt.say("#{Rainbow('Location:').bright.yellow} #{Rainbow(@output_dir).bright.white}")
          
          # Return success status and information
          { success: true, files_created: success_count, total_files: total_count, output_dir: @output_dir }
        end

        def extract_json(content)
          return nil if content.nil? || content.empty?

          # Handle case where the content is already a hash (it's been pre-parsed)
          return content if content.is_a?(Hash)

          # First try to extract JSON from code blocks with explicitly marked json
          json_match = content.match(/```(?:json)\s*(.*?)```/m)
          if json_match
            begin
              # Try with the content in the json code block
              json_str = json_match[1].strip
              # Ensure we have a complete JSON object
              if json_str.start_with?('{') && json_str.end_with?('}')
                return JSON.parse(json_str)
              end
            rescue JSON::ParserError => e
              puts "JSON parsing error from code block: #{e.message}" if @verbose
              # Continue to other extraction methods
            end
          end
          
          # Try to extract JSON from any code block
          code_match = content.match(/```\s*(.*?)```/m)
          if code_match
            begin
              # Try with the content in the code block
              code_str = code_match[1].strip
              # Only attempt to parse if it looks like JSON
              if code_str.start_with?('{') && code_str.end_with?('}')
                return JSON.parse(code_str)
              end
            rescue JSON::ParserError => e
              puts "JSON parsing error from any code block: #{e.message}" if @verbose
              # Continue to other extraction methods
            end
          end

          # Try to parse the entire content as JSON directly
          begin
            return JSON.parse(content)
          rescue JSON::ParserError
            # Continue to more aggressive extraction methods
          end
          
          # More aggressive extraction - find first { and last }
          begin
            if content =~ /\{.*\}/m
              # Try to extract the full JSON object using the balanced brace approach
              content_without_backticks = content.gsub(/```.*?```/m, '')
              opening_brace_index = content_without_backticks.index('{')
              
              if opening_brace_index
                # Find the matching closing brace by counting opening and closing braces
                open_count = 1
                closing_brace_index = nil

                ((opening_brace_index + 1)...content_without_backticks.length).each do |i|
                  char = content_without_backticks[i]
                  open_count += 1 if char == '{'
                  open_count -= 1 if char == '}'

                  if open_count.zero?
                    closing_brace_index = i
                    break
                  end
                end

                if closing_brace_index
                  json_block = content_without_backticks[opening_brace_index..closing_brace_index]
                  
                  # Debug output for troubleshooting
                  if @verbose
                    puts "Found JSON block: #{json_block[0..50]}..." 
                  end
                  
                  return JSON.parse(json_block)
                end
              end
            end
          rescue StandardError => e
            puts "Error during balanced brace extraction: #{e.message}" if @verbose
          end
          
          # Last resort - try to find something that looks like JSON using regex
          begin
            if match = content.match(/(\{.*\})/m)
              json_block = match[1]
              return JSON.parse(json_block)
            end
          rescue StandardError => e
            puts "Error during regex JSON extraction: #{e.message}" if @verbose
          end
          
          # If we got here, all extraction attempts failed
          nil
        end

        # A manual approach to extract key-value pairs when standard JSON parsing fails
        # This is a last resort for responses that are almost valid JSON but have some issues
        def manual_json_extraction(content)
          result = {}

          # Look for patterns like "key": "value" or "key": "multiline\nvalue"
          begin
            # Find content in code block if present
            json_content = content.match(/```(?:json)?\s*(\{.*?\})```/m)&.[](1) || content

            # Clean up the content - remove non-JSON parts outside of {}
            json_content = json_content.match(/(\{.*\})/m)[1] if json_content =~ /\{.*\}/m

            # Simple key-value extraction for one-level JSON objects
            # This won't handle nested objects properly but should work for simple file generation cases
            key_pattern = /"([^"]+)":\s*"([^"]*)"|"([^"]+)":\s*"([^"]*(?:\\"|[^"])*)"/m

            json_content.scan(key_pattern) do |k1, v1, k2, v2|
              key = k1 || k2
              value = v1 || v2

              # Unescape quotes and newlines
              value = value.gsub(/\\"/m, '"').gsub(/\\n/m, "\n") if value

              result[key] = value if key
            end

            # For directory entries without content (ending with /)
            dir_pattern = %r{"([^"]+/)"\s*:\s*""}
            json_content.scan(dir_pattern) do |dir|
              result[dir[0]] = ''
            end

            result.empty? ? nil : result
          rescue StandardError => e
            puts "Manual JSON extraction error: #{e.message}" if @verbose
            nil
          end
        end

        # Helper method to flatten nested JSON structures
        def flatten_nested_json_structure(json_content, base_path = '')
          flattened = {}
          
          return flattened if json_content.nil?
          
          # If we detect a common pattern where a file is represented with a hash containing a 'content' key
          # Extract just the content value to avoid the Ruby hash representation in file content
          if json_content.is_a?(Hash) && json_content.keys.size == 1 && json_content.key?('content')
            return { base_path => json_content['content'].to_s } unless base_path.empty? || 
                                                                       base_path == 'cookbook_name' || 
                                                                       base_path == 'directories'
            return {}
          end
          
          # If the JSON is already flattened (or a string), return it as is
          if json_content.is_a?(String) || !json_content.is_a?(Hash)
            return { base_path => json_content.to_s } unless base_path.empty? || 
                                                           base_path == 'cookbook_name' || 
                                                           base_path == 'directories'
            return {} # Skip if it's one of the special metadata keys
          end
          
          # Process each key-value pair in the JSON
          json_content.each do |key, value|
            # Skip special metadata keys that should not be created as files
            next if key == 'cookbook_name' || key == 'directories'
            next if key.start_with?('_') # Skip keys starting with underscore as metadata
            
            # Check for a common pattern where 'files' is an intermediate directory
            # We'll check if this is a standard structure and bypass the intermediate path
            if key == 'files' && value.is_a?(Hash)
              # Directly process the files content to avoid the extra 'files/' in paths
              nested = flatten_nested_json_structure(value, base_path)
              flattened.merge!(nested)
              next
            end
            
            path = base_path.empty? ? key : File.join(base_path, key)
            
            if value.is_a?(Hash)
              # Check for files with content in a hash with a 'content' key
              if value.keys.size == 1 && value.key?('content')
                flattened[path] = value['content'].to_s
                next
              end
              
              # If the value is a hash (nested structure), recursively flatten it
              if key.end_with?('/') || !key.include?('.')
                # Create the directory entry
                flattened[path + '/'] = ''
                
                # Recursively process the nested structure
                nested = flatten_nested_json_structure(value, path)
                flattened.merge!(nested)
              else
                # If the key has a file extension but the value is a hash,
                # check for content key or convert to a string in a smart way
                if value.key?('content')
                  flattened[path] = value['content'].to_s
                else
                  # Try to avoid raw hash representation
                  # For complex hashes, we'll use inspect but try to make it readable
                  flattened[path] = value.inspect
                end
              end
            else
              # If the value is not a hash, it's a file (or empty dir if key ends with /)
              flattened[path] = value.to_s
            end
          end
          
          flattened
        end
      end
    end
  end
end
