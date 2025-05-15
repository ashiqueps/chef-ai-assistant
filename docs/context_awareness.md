# Context Awareness

Chef AI Assistant provides two modes of context awareness when integrating with Chef ecosystem tools:

1. **Strict Context Mode (Default)**: In this mode, the AI will only answer questions specific to the tool it's integrated with. For example, when integrated with Knife, it will only answer Knife-related questions.

2. **Relaxed Context Mode**: In this mode, the AI can answer questions about the broader Chef ecosystem while still focusing on the integrated tool. For example, when integrated with Chef CLI, it can answer questions about Chef Client, Chef Server, and other Chef tools.

## How to Configure Context Mode

### Option 1: Using the Configuration Object

When configuring Chef AI Assistant, you can set the `strict_context_aware` option:

```ruby
ChefAiAssistant.configure do |config|
  config.integration_gem_name = 'chef'
  config.integration_gem_version = '1.0.0'
  config.integration_gem_description = 'Chef command-line tool'
  
  # Set to false for relaxed context mode
  config.strict_context_aware = false
end
```

### Option 2: Using Helper Methods

When integrating with another tool, you can use the helper methods:

```ruby
# For strict context mode (default)
ChefAiAssistant::Utils::CliHelper.configure_for_gem(AppClass, 'tool-name', { strict_context: true })

# For relaxed context mode
ChefAiAssistant::Utils::CliHelper.configure_for_gem(AppClass, 'tool-name', { strict_context: false })

# Alternative simplified method for relaxed context
ChefAiAssistant.register_commands_with_relaxed_context(AppClass, 'tool-name')
```

## Example Integration

### Strict Context Mode (Knife)

```ruby
# Configure Knife with strict context awareness
ChefAiAssistant::Utils::CliHelper.configure_for_gem(Knife::CLI, 'knife')

# With explicit strict context parameter
ChefAiAssistant::Utils::CliHelper.configure_for_gem(Knife::CLI, 'knife', { strict_context: true })
```

In this mode, if a user asks "How do I create a cookbook?", the AI will respond with:
"I'm currently integrated with knife and can only assist with knife-specific questions. For questions about chef-cli, please use the `chef-cli ai` command instead."

### Relaxed Context Mode (Chef CLI)

```ruby
# Configure Chef CLI with relaxed context awareness
ChefAiAssistant::Utils::CliHelper.configure_for_gem(ChefCLI::Application, 'chef-cli', { strict_context: false })

# Or use the convenience method
ChefAiAssistant.register_commands_with_relaxed_context(ChefCLI::Application, 'chef-cli')
```

In this mode, if a user asks "How do I create a cookbook?", the AI will provide a helpful answer about creating a cookbook, even though it's more related to Chef CLI than the core Chef tool.

## When to Use Each Mode

- **Use Strict Context Mode when:** You want to ensure users get clear boundaries between tools and guide them to use the correct CLI for specific tasks.

- **Use Relaxed Context Mode when:** You want to provide a more seamless experience where users can ask questions about the broader Chef ecosystem from a single tool.
