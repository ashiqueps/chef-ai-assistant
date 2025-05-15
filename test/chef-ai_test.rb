#!/usr/bin/env ruby
# frozen_string_literal: true

# This script tests the standalone chef-ai binary
# Usage: cd /path/to/chef-ai-assistant && ruby -I lib test/chef-ai_test.rb

require 'rainbow'

# Helper method to run a command and display output
def run_command(cmd)
  puts "> #{Rainbow(cmd).cyan}"
  system(cmd)
  puts "\n"
end

# Helper method to run a test case
def run_chef_ai_test(num, description, cmd)
  puts Rainbow("#{num}. #{description}").bright.yellow
  run_command(cmd)
end

puts Rainbow('Testing Standalone chef-ai binary').bright.blue.bold
puts ''

# Define test cases for standalone chef-ai binary
tests = [
  {
    description: "Testing 'chef-ai --help'",
    command: 'ruby -I lib bin/chef-ai --help'
  },
  {
    description: "Testing 'chef-ai --version'",
    command: 'ruby -I lib bin/chef-ai --version'
  },
  {
    description: 'Testing subcommand help (ask)',
    command: 'ruby -I lib bin/chef-ai ask --help'
  },
  {
    description: 'Testing subcommand help (command)',
    command: 'ruby -I lib bin/chef-ai command --help'
  },
  {
    description: 'Testing subcommand help (explain)',
    command: 'ruby -I lib bin/chef-ai explain --help'
  },
  {
    description: 'Testing subcommand help (generate)',
    command: 'ruby -I lib bin/chef-ai generate --help'
  },
  {
    description: 'Testing subcommand help (setup)',
    command: 'ruby -I lib bin/chef-ai setup --help'
  },
  {
    description: 'Testing subcommand help (troubleshoot)',
    command: 'ruby -I lib bin/chef-ai troubleshoot --help'
  }
]

# Run tests
tests.each_with_index do |test, index|
  run_chef_ai_test(index + 1, test[:description], test[:command])
end

puts "\n#{Rainbow('chef-ai Binary Tests Complete!').bright.green.bold}"
