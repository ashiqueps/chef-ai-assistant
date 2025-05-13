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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/username/chef-ai-assistant.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).