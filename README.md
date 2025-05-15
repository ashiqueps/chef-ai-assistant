# Chef AI Assistant

## What is Chef AI Assistant?

Chef AI Assistant is a Ruby gem that provides AI-powered capabilities for Chef infrastructure automation tools. It serves as both a standalone tool and an integration layer that can be embedded into existing Chef gems.

### As a Standalone Tool:
Chef AI Assistant provides a command-line interface through the `chef` command, offering AI-powered features for:
- Answering Chef-related questions
- Explaining Chef code and concepts
- Generating Chef commands from natural language
- Creating Chef cookbooks, recipes, and resources
- Troubleshooting Chef errors and issues
- Assisting with version migrations

### As an Integration Layer:
One of the key strengths of Chef AI Assistant is its ability to seamlessly integrate with existing Chef ecosystem tools. The gem is designed to:

- **Enhance Existing Tools**: Add AI capabilities to tools like Chef CLI, Knife, InSpec, and Test Kitchen
- **Context-Aware Integration**: Automatically detect the parent gem's context and tailor responses accordingly
- **Consistent Command Pattern**: Provide a uniform `ai` subcommand across all integrated Chef tools
- **Minimal Integration Effort**: Require only a few lines of code to integrate with any Chef gem
- **Shared Credentials**: Use a common credentials store across all integrated tools

### Why Integration Matters:
The integration capabilities of Chef AI Assistant are particularly important because:

1. **Unified Experience**: Users can access AI assistance through their familiar Chef tools without switching contexts
2. **Enhanced Productivity**: Tool-specific AI assistance is more relevant and actionable
3. **Broader Adoption**: Lower barrier to entry encourages more users to leverage AI capabilities
4. **Ecosystem Cohesion**: Strengthens the overall Chef ecosystem through consistent AI integration
5. **Future-Proof Design**: New AI capabilities automatically benefit all integrated tools

## Why Chef AI Assistant?

Chef is a powerful infrastructure automation platform, but its complexity can be challenging for both beginners and experienced users. Chef AI Assistant bridges this gap by providing an intelligent layer that simplifies interaction with the Chef ecosystem.

### For Beginners:
- **Flatten the Learning Curve**: Learn Chef concepts through natural language Q&A instead of wading through documentation
- **Command Generation**: Translate simple English requests into proper Chef commands with correct syntax
- **Error Diagnosis**: Get plain-English explanations and solutions for cryptic Chef errors
- **Code Explanation**: Understand existing cookbooks and recipes without having to decipher Ruby DSL

### For Experts:
- **Accelerate Workflow**: Generate complex commands and boilerplate code in seconds
- **Migration Assistance**: Automate the tedious process of migrating between Chef versions
- **Troubleshooting Partner**: Quickly diagnose and fix complex Chef-related issues
- **Context-Aware Help**: Get specialized assistance for specific Chef tools (Knife, InSpec, etc.)

### Key Benefits:
- **Increased Productivity**: Reduce time spent on routine Chef tasks by up to 70%
- **Improved Code Quality**: Generate well-structured, idiomatic Chef code following best practices
- **Reduced Support Burden**: Enable teams to solve their own Chef problems with AI assistance
- **Cross-Tool Integration**: Works seamlessly across the entire Chef ecosystem

Chef AI Assistant can be integrated with various Chef tools (Chef CLI, Knife, InSpec, etc.) and supports both strict and relaxed context awareness modes.

## Documentation

For comprehensive documentation, please visit:

- [Getting Started Guide](docs/getting_started.md) - Quick introduction to Chef AI Assistant
- [Installation Guide](docs/installation.md) - Detailed setup instructions
- [Configuration Guide](docs/configuration.md) - Configure Chef AI Assistant for your needs
- [Command Reference](docs/commands/index.md) - Detailed information about all commands
- [Integration Guide](docs/integration_guide.md) - How to integrate with Chef tools
- [Context Awareness](docs/context_awareness.md) - Learn about strict vs. relaxed context modes
- [Advanced Usage](docs/advanced_usage.md) - Advanced techniques and workflows
- [FAQ](docs/faq.md) - Common questions and answers

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'chef-ai-assistant'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install chef-ai-assistant

## Usage

### Command Line Interface

#### Using the Standalone Commands

Chef AI Assistant provides two standalone commands:

1. **`chef-ai` Command** - A streamlined standalone binary with simplified command structure:

```bash
# Basic usage (note there's no 'ai' subcommand needed)
chef-ai ask "How do I write a recipe for Apache installation?"
chef-ai explain path/to/cookbook
chef-ai command "list all nodes in production environment"

# Show help
chef-ai --help
chef-ai ask --help
```

2. **`chef` Command with AI Integration** - The traditional command structure:

```bash
# Basic usage
chef ai ask "How do I write a recipe for Apache installation?"
chef ai explain path/to/cookbook
chef ai command "list all nodes in production environment"

# Show help
chef --help
chef ai --help
```

For detailed usage of each subcommand, see the "Available Commands" section below.

#### Integrating with Other Chef Gems

Chef AI Assistant can also be integrated with other Chef gems (like chef-cli, knife, test-kitchen) to provide AI assistant capabilities via command line. 

The integration is context-aware, meaning that when integrated with specific Chef gems (like chef-cli, knife, test-kitchen, inspec, habitat, etc.), the AI assistant will:
- Automatically detect the parent gem's context
- Tailor its responses to focus on the specific gem's functionality 
- Generate commands and code relevant to that particular gem
- Provide explanations in the context of the parent gem
- Display integration information in help screens

To add the `ai` command to your Chef gem:

```ruby
require 'chef-ai-assistant'

# Register the AI commands with your main CLI class
# This will automatically detect the parent gem's name, version, and purpose
ChefAiAssistant.register_commands_with(YourGem::CLI)

# Configure any optional settings (credentials are handled by the setup command)
ChefAiAssistant.configure do |config|
  # Optional: Control whether responses are limited to the current tool's context
  config.strict_context_aware = true # Set to false for relaxed context mode
end

# You can also manually specify integration context for more precise control
ChefAiAssistant.integration_context = ChefAiAssistant::IntegrationContext.new(
  'your-gem-name',
  '1.2.3', # version
  'Your gem description and purpose'
)
```

Once integrated, users can access the AI assistant through your gem's CLI:

```
chef-cli ai ask "How do I write a recipe to install Nginx?"
```

#### Available Commands

Below are the available commands with both standalone (`chef-ai`) and integration (`chef ai`) usage examples:

- **Setup**: Configure Chef AI Assistant credentials
  ```bash
  # Standalone usage
  chef-ai setup

  # Integration usage
  chef ai setup
  ```
  
  Features:
  - Interactive wizard to set up Azure OpenAI credentials
  - Securely stores API key and other settings
  - Validates connection to ensure credentials work correctly
  
  Options:
  - `--force`: Overwrite existing credentials
  - `--help, -h`: Show help message

- **Ask**: Ask a question to the AI assistant
  ```bash
  # Standalone usage
  chef-ai ask "How do I write a recipe to configure a web server?"

  # Integration usage
  chef ai ask "How do I write a recipe to configure a web server?"
  ```
  
  Options:
  - `--temperature TEMP`: Set the response creativity (0.0-2.0)
  - `--system PROMPT`: Set a custom system prompt
  - `--verbose, -v`: Show detailed response information

- **Explain**: Get an explanation of Chef-related files or directories
  ```bash
  # Standalone usage
  chef-ai explain path/to/file.rb
  chef-ai explain path/to/directory

  # Integration usage
  chef ai explain path/to/file.rb
  chef ai explain path/to/directory
  ```

  Options:
  - `--temperature TEMP`: Set the response creativity (0.0-2.0)
  - `--verbose, -v`: Show detailed response information
  
- **ai generate**: Generate Chef ecosystem files from natural language descriptions
  ```
  chef ai generate "Create a cookbook for installing and configuring Nginx"
  chef ai generate "Write a recipe that installs MongoDB on Ubuntu"
  ```

  Features:
  - Creates complete Chef files based on natural language descriptions
  - Generates cookbooks, recipes, attributes, resources, and more
  - Follows best practices for Chef code structure and style
  - Creates comprehensive file structures with proper dependencies
  
  Options:
  - `--output PATH, -o PATH`: Specify output directory (default: current directory)
  - `--temperature TEMP`: Set the response creativity (0.0-2.0)
  - `--verbose, -v`: Show detailed response information

- **ai migrate**: Assist with migrations between different Chef versions
  ```
  chef ai migrate --from 14 --to 17 path/to/chef/file.rb
  chef ai migrate --from 15 --to 18 path/to/chef/directory
  ```

  Features:
  - Analyzes Chef code for compatibility issues between versions
  - Provides detailed information about version changes
  - Suggests fixes for deprecated features and syntax changes
  - Can perform automatic migration of files
  - Creates backups of original files or writes to a separate output directory
  
  Options:
  - `--from VERSION`: Source Chef version (e.g., 14)
  - `--to VERSION`: Target Chef version (e.g., 17)
  - `--output PATH`: Specify output directory for migrated files
  - `--scan-only`: Only scan for compatibility issues without making changes
  - `--temperature TEMP`: Set the response creativity (0.0-2.0)
  - `--verbose, -v`: Show detailed response information

- **ai command**: Generate Chef commands from natural language descriptions
  ```
  chef ai command "bootstrap a windows node"
  chef ai command "list all cookbooks on the server"
  ```

  Features:
  - Translates natural language into proper Chef commands
  - Provides explanations of what each command does
  - Handles multiple command options when available
  - Interactive prompts to fill in command placeholders
  - Displays the final command in a formatted box for easy copying
  
  Options:
  - `--temperature TEMP`: Set the response creativity (0.0-2.0)
  - `--verbose, -v`: Show detailed response information

- **ai troubleshoot**: Diagnose and troubleshoot Chef-related issues
  ```
  chef ai troubleshoot "Error message or description of the problem"
  chef ai troubleshoot path/to/error/log.log
  chef ai troubleshoot --logs path/to/chef/logs.log --config path/to/client.rb
  ```

  Features:
  - Analyzes error messages to provide solutions
  - Can examine log files for context and patterns
  - Processes configuration files to identify issues
  - Provides step-by-step solutions with clear formatting
  - Highlights warnings, errors, and solutions for easy scanning
  
  Options:
  - `--logs PATH`: Provide a path to Chef logs for analysis
  - `--config PATH`: Provide a path to Chef config file for analysis
  - `--temperature TEMP`: Set the response creativity (0.0-2.0)
  - `--verbose, -v`: Show detailed response information
  
## Examples

### Using the Command Generator

```
$ chef-ai command "bootstrap a windows node"
# or with the integration mode: chef ai command "bootstrap a windows node"

🔍 Processing:
  "bootstrap a windows node"
[...] Generating command...

🤖 Chef Command Generator:
To bootstrap a Windows node using Chef, you would typically use the `knife bootstrap windows winrm` command...

Available commands:
1. knife bootstrap windows winrm <NODE_IP> -x <USERNAME> -P <PASSWORD> --node-name <NODE_NAME> --run-list "<RUN_LIST>"
2. knife bootstrap windows winrm 192.168.1.100 -x Administrator -P 'SuperSecurePassword' --node-name webserver01 --run-list "recipe[iis]"

Enter number of command to use (or 0 to skip): 1
Enter value for NODE_IP: 192.168.1.156
Enter value for USERNAME: Administrator
Enter value for PASSWORD: SecurePassword
Enter value for NODE_NAME: win-node-1
Enter value for RUN_LIST: recipe[windows],recipe[iis]

============================================================
##  GENERATED CHEF COMMAND  ##
============================================================

    knife bootstrap windows winrm 192.168.1.156 -x Administrator -P SecurePassword --node-name win-node-1 --run-list "recipe[windows],recipe[iis]"
============================================================

✓ Just copy and paste this command into your terminal to use it.
```

### Using the Explain Feature

```
$ chef-ai explain cookbooks/apache
# or with the integration mode: chef ai explain cookbooks/apache

💼 Analyzing:
  cookbooks/apache
[...] Consulting AI assistant...

🤖 AI Explanation:
This directory contains a Chef cookbook named "apache" that's responsible for installing and configuring the Apache web server...
```

### Using the Troubleshoot Feature

```
$ chef-ai troubleshoot "ERROR: Connection refused connecting to localhost:8889"
# or with the integration mode: chef ai troubleshoot "ERROR: Connection refused connecting to localhost:8889"

🔍 Analyzing issue:
  "ERROR: Connection refused connecting to localhost:8889"
[...] Consulting AI assistant...

🔧 Troubleshooting Diagnosis:

This error occurs when Chef client is unable to connect to a service on port 8889 on localhost.

----------------------------------------
Solution:

Step 1: Verify if the service is running
Run the following command to check if anything is listening on port 8889:
  sudo lsof -i :8889

Step 2: Check firewall settings
Ensure that local connections on port 8889 are allowed:
  sudo iptables -L | grep 8889

Step 3: Examine Chef configuration
Make sure your Chef configuration is pointing to the correct endpoint and port.
Check your client.rb or knife.rb for any incorrect settings.

Step 4: Restart the service
If the service should be running on this port, try restarting it:
  sudo systemctl restart chef-service-name

Warning: Connection refused errors often indicate that a required service is not running or is misconfigured. Check the service's logs for additional clues.
```

### Using the Migrate Command

```
$ chef-ai migrate --from 14 --to 17 cookbooks/my_cookbook/recipes
# or with the integration mode: chef ai migrate --from 14 --to 17 cookbooks/my_cookbook/recipes

Chef Version Migration Overview:

Source: Chef 14 (Released: February 2018, EOL: April 2020)
Target: Chef 17 (Released: March 2021, EOL: April 2023)

Versions being skipped:
  Chef 15 (May 2019)
    • Chef Workstation replaces ChefDK
    • Chef InSpec integration
    • Target mode introduction
    • Multiple new resources

  Chef 16 (April 2020)
    • Unified Chef Infra Client
    • Improved resource subsystem
    • Many resources moved to core
    • Deprecation of legacy resources

New in Chef 17:
  • Ruby 3.0 support
  • New unified mode default for resources
  • Resource guard improvements
  • Compliance phase improvements

Do you want to proceed with the migration analysis? Yes
🔍 Analyzing Chef code for migration:
  Path: cookbooks/my_cookbook/recipes
  Migration: Chef 14 → Chef 17
  Mode: Full migration
  Found: 3 Chef files

Migration Analysis Results:
Files analyzed: 3
Files with issues: 2
Files without issues: 1

Files requiring migration:
  • default.rb
  • users.rb

Would you like to perform the migration? Yes

Creating backups in: cookbooks/my_cookbook/recipes/chef_migration_backup_20250513120113
  ✓ Migrated default.rb (1024 bytes)
  ✓ Migrated users.rb (895 bytes)

Migration Summary:
2 of 2 files migrated successfully
Original files backed up in: cookbooks/my_cookbook/recipes/chef_migration_backup_20250513120113
```

### Using the Generate Command

```
$ chef-ai generate "Create a cookbook for managing users"
# or with the integration mode: chef ai generate "Create a cookbook for managing users"

🔍 Processing:
  "Create a cookbook for managing users"
[...] Generating files...

🤖 Chef Generation Summary:
I'll create a 'users_cookbook' that manages system users with the following files:

├── metadata.rb
├── README.md
├── attributes/
│   └── default.rb
├── recipes/
│   ├── default.rb
│   ├── create.rb
│   └── remove.rb
├── templates/
│   └── user_profile.erb
└── test/
    └── integration/
        └── default/
            └── default_test.rb

Generating files... 

✅ Successfully generated:
metadata.rb (576 bytes)
README.md (1.2 KB)
attributes/default.rb (486 bytes)
recipes/default.rb (312 bytes)
recipes/create.rb (964 bytes)
recipes/remove.rb (482 bytes)
templates/user_profile.erb (125 bytes)
test/integration/default/default_test.rb (354 bytes)

This cookbook:
- Creates and manages system users across your infrastructure
- Allows customizing user attributes through node attributes
- Supports creating, modifying and removing users
- Includes test-kitchen integration tests

To use this cookbook:
1. Modify attributes/default.rb to configure your users
2. Include the default recipe in your run list
3. For advanced usage, include create or remove recipes directly
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ashiqueps/chef-ai-assistant.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).