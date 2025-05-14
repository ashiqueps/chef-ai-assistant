#!/usr/bin/env ruby
# frozen_string_literal: true

# This script tests all three integrations: chef, knife, and inspec
# Usage: cd /path/to/chef-ai-assistant && ruby -I lib test/integration_test.rb

require 'rainbow'

# Helper method to run a command and display output
def run_command(cmd)
  puts "> #{Rainbow(cmd).cyan}"
  system(cmd)
  puts "\n"
end

# Helper method to run an integration test case
def run_integration_test(num, description, cmd)
  puts Rainbow("#{num}. #{description}").bright.yellow
  run_command(cmd)
end

puts Rainbow("Testing Chef AI Assistant integration with different gems").bright.blue.bold
puts ""

# Define test cases for gem integration tests
gem_tests = [
  {
    description: "Testing default 'chef' integration",
    command: 'ruby -I lib bin/chef ai --help'
  },
  {
    description: "Testing 'knife' integration",
    command: 'ruby -I lib bin/knife ai --help'
  },
  {
    description: "Testing 'inspec' integration",
    command: 'ruby -I lib bin/inspec ai --help'
  }
]

# Run gem integration tests
gem_tests.each_with_index do |test, index|
  run_integration_test(index + 1, test[:description], test[:command])
end

puts Rainbow("Testing command generation with specific context").bright.blue.bold

# Define command generation tests
command_tests = [
  {
    description: "Testing 'knife' specialized command generation",
    command: 'ruby -I lib bin/knife ai command "list all nodes" --help'
  },
  {
    description: "Testing 'inspec' specialized command generation",
    command: 'ruby -I lib bin/inspec ai command "check if port 80 is open" --help'
  }
]

# Run command generation tests
command_tests.each_with_index do |test, index|
  run_integration_test(index + 4, test[:description], test[:command])
end

puts "\n#{Rainbow("Integration Test Complete!").bright.green.bold}"
