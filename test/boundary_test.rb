#!/usr/bin/env ruby
# frozen_string_literal: true

# This script tests the boundary enforcement behavior of the Chef AI Assistant
# Usage: ruby -I lib boundary_test.rb

require 'rainbow'

# Helper method to run a command and display output
def run_command(cmd)
  puts "> #{cmd}"  # Removed Rainbow.dim to avoid the error
  system(cmd)
  puts "\n"
end

# Helper method to run a boundary test case
def run_boundary_test(num, description, cmd)
  puts "#{num}. #{description}"  # Removed Rainbow formatting to avoid errors
  run_command(cmd)
end

puts Rainbow('Testing Chef AI Assistant Boundary Enforcement').bright.blue.bold
puts ''

# Define test cases for easier maintenance
test_cases = [
  {
    description: 'Testing boundary enforcement in knife - asking about InSpec',
    command: 'ruby -I lib test/bin/knife ai ask "How do I write an InSpec control to check port 80?"'
  },
  {
    description: 'Testing boundary enforcement in inspec - asking about knife',
    command: 'ruby -I lib test/bin/inspec ai ask "How do I list all nodes with knife?"'
  },
  {
    description: 'Testing command generation boundary enforcement in knife',
    command: 'ruby -I lib test/bin/knife ai command "generate an InSpec control to check port 80"'
  },
  {
    description: 'Testing proper functionality with related questions',
    command: 'ruby -I lib test/bin/knife ai ask "How do I list all nodes?"'
  }
]

# Run all test cases
test_cases.each_with_index do |test_case, index|
  run_boundary_test(
    index + 1,
    test_case[:description],
    test_case[:command]
  )
end

puts "\n#{Rainbow('Boundary Enforcement Test Complete!').bright.green.bold}"
