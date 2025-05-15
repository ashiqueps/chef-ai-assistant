# Integration Guide

This guide explains how to integrate Chef AI Assistant with other Chef gems to provide AI capabilities through their CLI interfaces.

## Overview

Chef AI Assistant can be integrated with various Chef tools (Chef CLI, Knife, InSpec, etc.) to provide AI-powered assistance directly through their command-line interfaces. This integration enables context-aware AI help that's specific to each tool.

## Integration Benefits

- **Consistent Experience**: Add the same AI capabilities across all your Chef tools
- **Context Awareness**: AI responses tailored to the specific tool's context
- **Seamless Workflow**: Access AI assistance without switching tools
- **Customized Help**: Tool-specific guidance and examples

## Supported Integrations

Chef AI Assistant can be integrated with:

- **Chef Infra CLI** (`chef`)
- **Knife** (`knife`)
- **InSpec** (`inspec`)
- **Test Kitchen** (`kitchen`)
- **Habitat** (`hab`)
- **Berkshelf** (`berks`)
- **ChefSpec** (through RSpec)
- **Custom Chef-related gems**

## Integration Methods

### Method 1: Automatic Integration with Common Chef Tools

For common Chef tools, integration can be as simple as requiring the gem:

```ruby
# For example, in knife's plugin file
require 'chef-ai-assistant'
```

Chef AI Assistant will automatically detect the parent gem context.

### Method 2: Explicit Registration with CLI Class

For more control, explicitly register Chef AI Assistant with your CLI class:

```ruby
require 'chef-ai-assistant'

# Register the AI commands with your main CLI class
ChefAiAssistant.register_commands_with(YourGem::CLI)

# Configure the AI assistant with your Azure OpenAI credentials
# This can also be done using environment variables or the setup command
ChefAiAssistant.configure do |config|
  config.api_key = ENV['AZURE_OPENAI_API_KEY']
  config.azure_endpoint = ENV['AZURE_OPENAI_ENDPOINT']
  config.deployment_name = ENV['AZURE_OPENAI_DEPLOYMENT_NAME']
end
```

### Method 3: Manual Context Specification

For complete control over the integration context:

```ruby
require 'chef-ai-assistant'

# Register commands
ChefAiAssistant.register_commands_with(YourGem::CLI)

# Manually specify integration context
ChefAiAssistant.integration_context = ChefAiAssistant::IntegrationContext.new(
  'your-gem-name',
  '1.2.3', # version
  'Your gem description and purpose'
)

# Configure credentials
ChefAiAssistant.configure do |config|
  # Configuration options
end
```

## Integration Code Examples

### Chef Infra Integration

```ruby
# In a Chef Infra plugin file
require 'chef-ai-assistant'

module ChefCLI
  module Command
    class Base
      # Your existing code...
    end
  end
end

# Register AI commands with Chef CLI
ChefAiAssistant.register_commands_with(ChefCLI::Command::Base)
```

### Knife Integration

```ruby
# In a Knife plugin file
require 'chef-ai-assistant'
require 'chef/knife'

# Register AI commands with Knife
ChefAiAssistant.register_commands_with(Chef::Knife)
```

### InSpec Integration

```ruby
# In an InSpec plugin file
require 'chef-ai-assistant'
require 'inspec/plugins'

# Register AI commands with InSpec
ChefAiAssistant.register_commands_with(Inspec::Plugins::CLI)

# Specify InSpec context explicitly (optional)
ChefAiAssistant.integration_context = ChefAiAssistant::IntegrationContext.new(
  'inspec',
  Inspec::VERSION,
  'Chef InSpec security and compliance automation'
)
```

## Context Awareness

When integrated, Chef AI Assistant becomes aware of its parent tool context:

1. **Detection**: Automatically identifies the parent gem name, version, and purpose
2. **Specialization**: Tailors responses to focus on the specific tool's functionality
3. **Boundaries**: In strict mode, only answers questions relevant to the current tool
4. **Referrals**: Suggests using the appropriate tool for questions outside its scope

For example, when integrated with InSpec, the AI will:
- Focus on compliance and security testing
- Provide InSpec-specific code examples
- Reference InSpec resources and APIs
- Only answer InSpec-related questions in strict mode

## Command Availability

After integration, users can access AI commands through the parent CLI:

```bash
# With Chef CLI integration
chef ai ask "How do I write a recipe?"

# With Knife integration
knife ai explain path/to/cookbook

# With InSpec integration
inspec ai generate "Create a control for SSH settings"
```

All standard Chef AI Assistant commands become available through the parent CLI.

## Configuration Inheritance

Integrated instances can inherit configuration:

1. From environment variables
2. From configuration files
3. From programmatic configuration

## Testing Your Integration

To test your integration:

1. Build and install your gem with Chef AI Assistant integration
2. Run the setup command: `your-gem ai setup`
3. Test a simple command: `your-gem ai ask "What can you help me with?"`
4. Verify context awareness: `your-gem ai ask "What gem are you integrated with?"`

## Troubleshooting Integration Issues

Common integration issues:

1. **Command Not Found**: Ensure `register_commands_with` is called with the correct CLI class
2. **Context Detection Failure**: Use explicit context specification
3. **Credential Issues**: Run `your-gem ai setup` to configure credentials

For more help, see the [Troubleshooting](troubleshooting.md) guide.

## See Also

- [Context Awareness](context_awareness.md): More details on strict vs. relaxed context modes
- [Configuration](configuration.md): Configuration options
