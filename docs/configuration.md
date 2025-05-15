# Configuration Guide

This guide explains how to configure Chef AI Assistant for optimal performance and security.

## Configuration Methods

Chef AI Assistant offers several methods for configuration to fit various environments and workflows:

1. Interactive setup wizard
2. Environment variables
3. Programmatic configuration
4. Configuration file

## Method 1: Interactive Setup Wizard

The simplest way to configure Chef AI Assistant is through the setup wizard:

```bash
chef ai setup
```

The wizard will prompt you for:
- Azure OpenAI API key
- Azure endpoint URL
- Deployment name
- Additional optional settings

Your credentials are securely stored in `~/.chef/ai_credentials` with read/write permissions restricted to your user account only.

## Method 2: Environment Variables

For automation, CI/CD pipelines, or containerized environments, you can use environment variables:

```bash
# Required variables
export AZURE_OPENAI_API_KEY=your_api_key
export AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com
export AZURE_OPENAI_DEPLOYMENT_NAME=your_deployment_name

# Optional variables
export AZURE_OPENAI_API_VERSION=2023-05-15 # Default
export CHEF_AI_STRICT_CONTEXT=true        # Default
```

You can set these variables in your shell profile, or for a specific project, use a `.env` file.

## Method 3: Programmatic Configuration

When integrating Chef AI Assistant into your own Ruby applications:

```ruby
require 'chef-ai-assistant'

ChefAiAssistant.configure do |config|
  config.api_key = 'your-azure-openai-api-key'
  config.api_version = '2023-05-15'  # Optional, defaults to this version
  config.azure_endpoint = 'https://your-resource-name.openai.azure.com'
  config.deployment_name = 'your-model-deployment-name'
  
  # Optional configuration
  config.strict_context_aware = true  # Default
end
```

## Method 4: Configuration File

You can also create a configuration file at `~/.chef/ai_config.json`:

```json
{
  "api_key": "your-azure-openai-api-key",
  "api_version": "2023-05-15",
  "azure_endpoint": "https://your-resource-name.openai.azure.com",
  "deployment_name": "your-model-deployment-name",
  "strict_context_aware": true
}
```

## Configuration Options

| Option | Description | Default | Environment Variable |
|--------|-------------|---------|---------------------|
| `api_key` | Your Azure OpenAI API key | None (Required) | `AZURE_OPENAI_API_KEY` |
| `azure_endpoint` | Your Azure OpenAI endpoint URL | None (Required) | `AZURE_OPENAI_ENDPOINT` |
| `deployment_name` | Your model deployment name | None (Required) | `AZURE_OPENAI_DEPLOYMENT_NAME` |
| `api_version` | Azure OpenAI API version | `2023-05-15` | `AZURE_OPENAI_API_VERSION` |
| `strict_context_aware` | Whether to enforce strict tool context boundaries | `true` | `CHEF_AI_STRICT_CONTEXT` |

## Context Awareness Configuration

Chef AI Assistant supports both strict and relaxed context awareness modes:

- **Strict Mode** (default): The AI will only respond to queries specific to the current tool context
- **Relaxed Mode**: The AI will respond to queries across the Chef ecosystem

To change the mode:

```ruby
ChefAiAssistant.configure do |config|
  config.strict_context_aware = false  # Enable relaxed mode
end
```

Or via environment variable:

```bash
export CHEF_AI_STRICT_CONTEXT=false
```

See [Context Awareness](context_awareness.md) for more details.

## Security Considerations

- **API Key Storage**: Credentials are stored with `0600` permissions (owner read/write only)
- **Environment Variables**: Avoid hardcoding credentials; use environment variables instead
- **Connection Security**: All API communication uses HTTPS encryption
- **Token Rotation**: Consider rotating your API keys periodically

## Troubleshooting Configuration Issues

If you encounter configuration problems:

1. Verify your credentials are correct in Azure portal
2. Check for typos in endpoint URLs
3. Ensure your deployment is active in Azure OpenAI 
4. Try the setup wizard to validate your configuration: `chef ai setup --force`

For more help, consult the [Troubleshooting](troubleshooting.md) guide.
