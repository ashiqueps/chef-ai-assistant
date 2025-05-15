# Context-Aware Chef AI Assistant

## Architecture Changes Summary

This document outlines the architectural changes made to make Chef AI Assistant context-aware based on the parent gem it's integrated with.

## Key Components Added

### 1. Integration Context Class
- Created a new `IntegrationContext` class to track which gem has integrated the Chef AI Assistant
- Stores parent gem's name, version, and description
- Provides specialized instructions based on gem type (chef-cli, knife, test-kitchen, etc.)
- Offers context-specific system prompts for different command types (ask, command, explain, etc.)

### 2. Main Module Enhancement
- Updated `register_commands_with` to automatically detect parent gem information
- Added methods to determine parent gem name, version, and description
- Added integration context tracking to the main ChefAiAssistant module

### 3. Dynamic System Prompts
- Added `load_system_prompt` method in base command class
- Made system prompts context-aware based on parent gem
- Ensured all subcommands use appropriate context-specific prompts

### 4. Subcommand Updates
- Refactored all subcommands (ask, command, explain, generate, migrate, troubleshoot) to use dynamic system prompts
- Made each subcommand aware of the integration context
- Tailored command-specific instructions to focus on parent gem functionality

### 5. User Interface Improvements
- Enhanced help display to show integration information
- Updated version information to include parent gem details
- Improved command examples to use correct command prefixes

## Integration Example

```ruby
# Simple integration - automatic context detection
ChefAiAssistant.register_commands_with(YourGem::CLI)

# Advanced integration with manual context specification
ChefAiAssistant.register_commands_with(YourGem::CLI)
ChefAiAssistant.integration_context = ChefAiAssistant::IntegrationContext.new(
  'your-gem-name',
  '1.2.3',
  'Your gem description and purpose'
)
```

## Benefits

1. **Context-Aware Responses**: AI responses are tailored to the specific gem's functionality
2. **Focused Assistance**: Commands and explanations are relevant to the parent gem's domain
3. **Better User Experience**: Help screens show integration information for clarity
4. **Consistent Interface**: Commands remain the same but with context-appropriate behavior
5. **Flexible Integration**: Works automatically but allows manual customization if needed

## Parent Gem Specializations

- **chef-cli**: Development workflows, cookbook authoring, testing frameworks
- **knife**: Infrastructure management, Chef Server communication, node operations
- **test-kitchen**: Infrastructure testing, verification, driver configuration
- **inspec**: Compliance automation, security controls, compliance profiles
- **habitat**: Application packaging, service runtime, deployment operations
