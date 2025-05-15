# frozen_string_literal: true

require 'erb'

module ChefAiAssistant
  module Utils
    # Handles loading and rendering of ERB templates for AI prompts
    class PromptRenderer
      attr_reader :templates_path, :templates_cache

      def initialize(templates_path = nil)
        @templates_path = templates_path || File.join(File.dirname(__FILE__), '..', 'commands', 'ai',
                                                      'prompt_templates')
        @templates_cache = {}
      end

      # Render a template with the given variables
      def render(template_name, variables = {})
        # Ensure we have valid variables, especially integration_context
        variables = ensure_valid_variables(variables)

        begin
          template = load_template(template_name)
          context = RenderingContext.new(templates_path, variables)

          result = template.result(context.get_binding)

          # Sanity check - make sure we got something back
          if result.nil? || result.empty?
            puts "Warning: Template #{template_name} rendered empty result" if ENV['DEBUG']
            return fallback_prompt(variables)
          end

          result
        rescue SyntaxError => e
          # Specific handling for syntax errors in ERB templates
          puts "Warning: Syntax error in template #{template_name}: #{e.message}" if ENV['DEBUG']
          puts "Template error location: #{e.backtrace.join("\n")}" if ENV['DEBUG']
          fallback_prompt(variables)
        rescue LoadError => e
          # Missing dependency errors
          puts "Warning: Missing dependency for template #{template_name}: #{e.message}" if ENV['DEBUG']
          fallback_prompt(variables)
        rescue StandardError => e
          # If template rendering fails for any reason, return a basic prompt
          puts "Warning: Failed to render template #{template_name}: #{e.message}" if ENV['DEBUG']
          puts "Error backtrace: #{e.backtrace.join("\n")}" if ENV['DEBUG']
          fallback_prompt(variables)
        end
      end

      private

      # Generate a fallback prompt when templates fail
      def fallback_prompt(variables)
        # Extract useful information for the fallback prompt
        gem_name = if variables[:integration_context].respond_to?(:parent_gem_name)
                     variables[:integration_context].parent_gem_name
                   elsif variables[:integration_context].is_a?(String)
                     variables[:integration_context]
                   else
                     'chef'
                   end

        command_type = variables[:command_type] || 'general'

        # Create a basic but helpful prompt
        prompt = "You are a Chef AI Assistant focusing on #{gem_name}. "
        prompt += "You specialize in helping with #{command_type} tasks. "
        prompt += 'Provide clear, concise answers to Chef-related questions.'

        # Add context awareness information if available
        if variables[:strict_context] == false
          prompt += ' You can answer questions about the entire Chef ecosystem.'
        elsif gem_name != 'chef'
          prompt += " Focus on #{gem_name}-specific functionality."
        end

        prompt
      end

      # Ensure we have valid variables to prevent nil errors
      def ensure_valid_variables(variables)
        result = variables.dup

        # If integration_context is nil, create a default
        unless result[:integration_context]
          if ChefAiAssistant.respond_to?(:integration_context) && ChefAiAssistant.integration_context
            result[:integration_context] = ChefAiAssistant.integration_context
          else
            # Create a minimal string as fallback
            result[:integration_context] = 'chef'
          end
        end

        # Set command_type if not present
        result[:command_type] ||= 'general'

        # Set strict_context if not present
        if result[:strict_context].nil? && ChefAiAssistant.respond_to?(:configuration)
          result[:strict_context] = ChefAiAssistant.configuration.strict_context_aware
        end

        result
      end

      # Load a template from disk or cache
      def load_template(template_name)
        @templates_cache[template_name] ||= begin
          template_path = File.join(templates_path, "#{template_name}.erb")

          unless File.exist?(template_path)
            raise ArgumentError, "Template '#{template_name}' not found at #{template_path}"
          end

          template_content = File.read(template_path)
          ERB.new(template_content, trim_mode: '-')
        end
      end
    end

    # Context object used for rendering ERB templates with helper methods
    class RenderingContext
      def initialize(templates_path, variables)
        @templates_path = templates_path
        @renderer = PromptRenderer.new(templates_path)

        # Make all variables available as instance variables
        variables.each do |key, value|
          instance_variable_set("@#{key}", value)

          # Also make all variables available as methods
          define_singleton_method(key) { value }
        end
      end

      # Render another template (for template composition)
      def render(template_name)
        # Extract all instance variables into a hash
        variables = {}
        instance_variables.each do |var|
          next if %i[@renderer @templates_path].include?(var)

          variables[var.to_s[1..-1].to_sym] = instance_variable_get(var)
        end

        @renderer.render(template_name, variables)
      end

      # Expose binding for ERB
      def get_binding
        binding
      end
    end
  end
end
