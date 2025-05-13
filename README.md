# Chef AI Assistant

Chef AI Assistant is a Ruby gem that provides AI-powered capabilities for Chef. It helps with explaining Chef code, generating Chef commands, and answering questions about Chef.

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

### Configuration

Configure the Azure OpenAI client with your credentials:

```ruby
require 'chef-ai-assistant'

# Set up configuration with environment variables
# AZURE_OPENAI_API_KEY, AZURE_OPENAI_ENDPOINT, AZURE_OPENAI_DEPLOYMENT_NAME

# Environment variables can be loaded from a .env file
# Create a .env file with:
# AZURE_OPENAI_API_KEY=your_api_key
# AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com
# AZURE_OPENAI_DEPLOYMENT_NAME=your_deployment_name

# Or configure manually
ChefAiAssistant.configure do |config|
  config.api_key = 'your-azure-openai-api-key'
  config.api_version = '2023-05-15' # Optional, defaults to this version
  config.azure_endpoint = 'https://your-resource-name.openai.azure.com'
  config.deployment_name = 'your-model-deployment-name'
end
```

### Using the Azure OpenAI Client

```ruby
# Create a client using the configured settings
client = ChefAiAssistant.openai_client

# Send a chat request
response = client.chat("Hello, how can you help me with my Chef recipes?")
puts response.dig("choices", 0, "message", "content")

# Advanced usage with options
response = client.chat(
  "What's a good recipe for pasta?",
  {
    messages: [
      { role: "system", content: "You are a chef assistant that helps with recipes." },
      { role: "user", content: "What's a good recipe for pasta?" }
    ],
    temperature: 0.5,
    max_tokens: 1000
  }
)
```

### Command Line Interface

#### Using the Standalone `chef` Command

Chef AI Assistant comes with a standalone `chef` command that provides easy access to all AI assistant features:

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

To add the `ai` command to your Chef gem:

```ruby
require 'chef-ai-assistant'

# Register the AI commands with your main CLI class
ChefAiAssistant.register_commands_with(YourGem::CLI)

# Configure the AI assistant
ChefAiAssistant.configure do |config|
  # Configuration as shown in the Configuration section
end
```

Once integrated, users can access the AI assistant through your gem's CLI:

```
chef-cli ai ask "How do I write a recipe to install Nginx?"
```

#### Available Commands

- **ai**: The main command that provides access to AI assistant features
  ```
  chef ai --help
  ```

- **ai ask**: Ask a question to the AI assistant
  ```
  chef ai ask "How do I write a recipe to configure a web server?"
  ```
  
  Options:
  - `--temperature TEMP`: Set the response creativity (0.0-2.0)
  - `--system PROMPT`: Set a custom system prompt
  - `--verbose, -v`: Show detailed response information

- **ai explain**: Get an explanation of Chef-related files or directories
  ```
  chef ai explain path/to/file.rb
  chef ai explain path/to/directory
  ```

  Options:
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
$ chef ai command "bootstrap a windows node"

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
$ chef ai explain cookbooks/apache

💼 Analyzing:
  cookbooks/apache
[...] Consulting AI assistant...

🤖 AI Explanation:
This directory contains a Chef cookbook named "apache" that's responsible for installing and configuring the Apache web server...
```

### Using the Troubleshoot Feature

```
$ chef ai troubleshoot "ERROR: Connection refused connecting to localhost:8889"

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
$ chef ai migrate --from 14 --to 17 cookbooks/my_cookbook/recipes

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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ashiqueps/chef-ai-assistant.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).