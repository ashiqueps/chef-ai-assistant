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
        template = load_template(template_name)
        context = RenderingContext.new(templates_path, variables)

        begin
          result = template.result(context.get_binding)
          # Sanity check - make sure we got something back
          if result.nil? || result.empty?
            puts "Warning: Template #{template_name} rendered empty result" if ENV['DEBUG']
            return "You are a Chef AI Assistant focusing on #{variables[:integration_context]&.parent_gem_name || 'chef'}."
          end
          result
        rescue SyntaxError => e
          # Specific handling for syntax errors in ERB templates
          puts "Warning: Syntax error in template #{template_name}: #{e.message}" if ENV['DEBUG']
          puts "Template error location: #{e.backtrace.join("\n")}" if ENV['DEBUG']
          "You are a Chef AI Assistant focusing on #{variables[:integration_context]&.parent_gem_name || 'chef'}."
        rescue StandardError => e
          # If template rendering fails, return a basic prompt
          puts "Warning: Failed to render template #{template_name}: #{e.message}" if ENV['DEBUG']
          puts "Error backtrace: #{e.backtrace.join("\n")}" if ENV['DEBUG']
          "You are a Chef AI Assistant focusing on #{variables[:integration_context]&.parent_gem_name || 'chef'}."
        end
      end

      private

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
