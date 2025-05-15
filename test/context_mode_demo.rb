#!/usr/bin/env ruby
# frozen_string_literal: true

# This script demonstrates how to use both strict and relaxed context modes

require 'bundler/setup'
require 'chef-ai-assistant'
require 'tty-prompt'
require 'rainbow'

TTY::Prompt.new
puts Rainbow('Context Mode Demonstration').bright.magenta.bold

# Mock classes to simulate different integrations
module Test
  class KnifeIntegration
    def self.name
      'Test::KnifeIntegration'
    end
  end

  class ChefIntegration
    def self.name
      'Test::ChefIntegration'
    end
  end
end

# Helper method to display configuration
def display_integration(name, strict)
  puts "\n#{Rainbow("#{name} Integration (#{strict ? 'Strict' : 'Relaxed'} Context Mode)").bright.blue.bold}"
  puts "  Integration Name: #{ChefAiAssistant.integration_context.parent_gem_name}"
  puts "  Context Mode: #{ChefAiAssistant.configuration.strict_context_aware ? 'Strict' : 'Relaxed'}"

  # Show example system prompt that would be used
  context_type = if ChefAiAssistant.configuration.strict_context_aware
                   "Only answers questions about #{ChefAiAssistant.integration_context.parent_gem_name}"
                 else
                   'Can answer questions about the broader Chef ecosystem'
                 end
  puts "  Behavior: #{context_type}"
end

# Using the direct configuration method
puts Rainbow("\nExample 1: Direct Configuration").yellow
spinner = TTY::Spinner.new('[:spinner] Configuring Knife with strict context...', format: :dots)
spinner.auto_spin

ChefAiAssistant.configure do |config|
  config.integration_gem_name = 'knife'
  config.integration_gem_version = ChefAiAssistant::VERSION
  config.integration_gem_description = 'Chef knife tool for Chef Server interaction and node management'
  config.strict_context_aware = true
end

spinner.success
display_integration('Knife', true)

# Using the helper method with strict context
puts Rainbow("\nExample 2: Helper Method with Strict Context").yellow
spinner = TTY::Spinner.new('[:spinner] Configuring Knife with strict context via helper...', format: :dots)
spinner.auto_spin

ChefAiAssistant::Utils::CliHelper.configure_for_gem(Test::KnifeIntegration, 'knife', { strict_context: true })

spinner.success
display_integration('Knife', true)

# Using the relaxed context helper method
puts Rainbow("\nExample 3: Helper Method with Relaxed Context").yellow
spinner = TTY::Spinner.new('[:spinner] Configuring Chef with relaxed context via helper...', format: :dots)
spinner.auto_spin

ChefAiAssistant.register_commands_with_relaxed_context(Test::ChefIntegration, 'chef')

spinner.success
display_integration('Chef', false)

puts "\n#{Rainbow('Example System Prompts:').bright.yellow.bold}"
puts Rainbow('Strict Mode:').blue
puts ChefAiAssistant.integration_context.specialized_system_prompt(
  'You are a Chef expert AI assistant.',
  'ask'
).gsub(/^/, '  ')

# Switch to relaxed mode for comparison
ChefAiAssistant.configure do |config|
  config.strict_context_aware = false
end

puts Rainbow("\nRelaxed Mode:").blue
puts ChefAiAssistant.integration_context.specialized_system_prompt(
  'You are a Chef expert AI assistant.',
  'ask'
).gsub(/^/, '  ')

puts "\n#{Rainbow('Integration Complete').green.bold}"
puts 'You can now create integrations with both strict and relaxed context modes!'
