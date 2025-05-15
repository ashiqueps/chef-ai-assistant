# Getting Started with Chef AI Assistant

This guide will help you get started with Chef AI Assistant and understand how it can transform your Chef workflow.

## What is Chef AI Assistant?

Chef AI Assistant is a Ruby gem that integrates AI-powered assistance into the Chef ecosystem. It helps users interact with Chef tools, understand Chef code, generate commands and recipes, and troubleshoot issues.

## Key Features

- **Natural Language Interaction**: Ask questions about Chef in plain English
- **Code Explanation**: Get clear explanations of Chef code and cookbooks
- **Command Generation**: Convert natural language descriptions into proper Chef commands
- **Troubleshooting**: Diagnose and solve Chef-related issues
- **Migration Assistance**: Help migrating between different Chef versions
- **Code Generation**: Create Chef cookbooks, recipes, and other components from descriptions

## Prerequisites

Before installing Chef AI Assistant, ensure you have:

1. Ruby 2.7 or higher
2. Access to Azure OpenAI API (for AI capabilities)

## Quick Start

### 1. Install the Gem

```ruby
gem install chef-ai-assistant
```

### 2. Configure API Access

Run the setup command to configure your Azure OpenAI API credentials:

```bash
# Standalone command
chef-ai setup

# Or with Chef integration
chef ai setup
```

Follow the interactive prompts to enter your API credentials.

### 3. Try Your First Command

Ask a question about Chef:

```bash
# Standalone command
chef-ai ask "How do I write a recipe to install Nginx?"

# Or with Chef integration
chef ai ask "How do I write a recipe to install Nginx?"
```

### 4. Explore More Commands

Get help on all available commands:

```bash
# Standalone command
chef-ai --help

# Or with Chef integration
chef ai --help
```

## Next Steps

- Review the [Installation Guide](installation.md) for detailed setup instructions
- Learn about [Configuration Options](configuration.md)
- See the [Command Reference](commands/index.md) for all available commands
- Explore [Integration Guide](integration_guide.md) to add AI capabilities to your Chef tools

## Example Session

Here's what a simple interaction with Chef AI Assistant looks like:

```bash
$ chef-ai ask "What is a cookbook?"
# Or: $ chef ai ask "What is a cookbook?"

🔍 Processing:
  "What is a cookbook?"
[...] Consulting AI assistant...

🤖 AI Response:
In Chef, a cookbook is the fundamental unit of configuration and policy distribution. Here's what you need to know:

A cookbook:
- Contains recipes, attributes, resources, templates, and other components
- Defines everything needed to configure a part of your infrastructure
- Can be shared and reused across different environments

The basic structure of a cookbook includes:
- metadata.rb: Defines cookbook properties like name, version, and dependencies
- recipes/default.rb: Contains the primary configuration code
- attributes/: Defines customizable values used in recipes
- templates/: Contains ERB template files
- resources/: Holds custom resources
- libraries/: Contains Ruby helper code

Cookbooks follow a specific directory structure and naming conventions to ensure they work properly with the Chef ecosystem.
```

For more detailed information on specific topics, please explore the rest of our documentation.
