require 'optparse'

module ChefAiAssistant
  module Commands
    class Ai
      class Ask < ChefAiAssistant::Command::Base
        def setup_command
          @name = "ask"
          @description = "Ask the AI assistant a question"
          @banner = "Usage: PARENT_COMMAND ai ask QUESTION [options]"
          @options = {
            "--help, -h" => "Show this message",
            "--temperature TEMP" => "Set the response creativity (0.0-2.0)",
            "--system PROMPT" => "Set a custom system prompt",
            "--verbose, -v" => "Show detailed response information"
          }
          @verbose = false
          @temperature = 0.7
          @system_prompt = "You are a helpful AI assistant for Chef. Help answer questions about Chef recipes, infrastructure, and general cooking questions."
        end

        def run(args = [])
          if args.empty? || args.include?("--help") || args.include?("-h")
            help
            return 0
          end

          # Parse options
          remaining_args = parse_options(args)

          # The remaining args should be the question
          question = remaining_args.join(" ")
          if question.empty?
            puts "Error: Please provide a question"
            help
            return 1
          end

          # Process the question with the AI assistant
          process_question(question)
          
          return 0
        end

        def parse_options(args)
          parser = OptionParser.new do |opts|
            opts.banner = @banner
            
            opts.on("-h", "--help", "Show this message") do
              help
              exit 0
            end
            
            opts.on("--temperature TEMP", Float, "Set the response creativity (0.0-2.0)") do |temp|
              @temperature = temp
              @temperature = 0.0 if @temperature < 0
              @temperature = 2.0 if @temperature > 2.0
            end
            
            opts.on("--system PROMPT", String, "Set a custom system prompt") do |prompt|
              @system_prompt = prompt
            end
            
            opts.on("-v", "--verbose", "Show detailed response information") do
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
          begin
            client = ChefAiAssistant.openai_client
            
            # Create messages array with system and user prompts
            messages = [
              { role: "system", content: @system_prompt },
              { role: "user", content: question }
            ]
            
            puts "Asking AI assistant: #{question}"
            puts "Thinking..." 
            
            # Send the request to the AI
            response = client.chat(nil, {
              messages: messages,
              temperature: @temperature
            })
            
            # Extract and display the response
            content = response.dig("choices", 0, "message", "content")
            
            if content
              puts "\nAI Assistant:"
              puts "#{content}\n"
              
              if @verbose
                puts "\nResponse Details:"
                puts "- Model: #{response['model']}"
                puts "- Finish reason: #{response.dig('choices', 0, 'finish_reason')}"
                puts "- Prompt tokens: #{response.dig('usage', 'prompt_tokens')}"
                puts "- Completion tokens: #{response.dig('usage', 'completion_tokens')}"
                puts "- Total tokens: #{response.dig('usage', 'total_tokens')}"
              end
            else
              puts "Error: Failed to get a response from the AI assistant"
            end
            
          rescue => e
            puts "Error: #{e.message}"
            if @verbose
              puts e.backtrace
            end
          end
        end
      end
    end
  end
end