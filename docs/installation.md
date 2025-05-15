# Installation Guide

This guide provides detailed instructions for installing Chef AI Assistant in various environments.

## System Requirements

- Ruby 2.7 or higher
- Bundler (recommended)
- Access to Azure OpenAI API (for AI capabilities)

## Installation Methods

### Method 1: Install from RubyGems

The simplest method to install Chef AI Assistant is directly from RubyGems:

```bash
gem install chef-ai-assistant
```

### Method 2: Using Bundler

If you're integrating with an existing Ruby project, add Chef AI Assistant to your Gemfile:

```ruby
# In your Gemfile
gem 'chef-ai-assistant', '~> 1.0'
```

Then install using Bundler:

```bash
bundle install
```

### Method 3: From Source

For the latest development version or contributing to the gem:

```bash
git clone https://github.com/ashiqueps/chef-ai-assistant.git
cd chef-ai-assistant
bundle install
rake install
```

## Verifying Your Installation

Verify that Chef AI Assistant was installed correctly:

```bash
# Standalone command
chef-ai --version

# Or with Chef integration
chef --version
```

You should see output that includes the Chef AI Assistant version.

## Initial Setup

After installation, you need to configure your API credentials:

```bash
# Standalone command
chef-ai setup

# Or with Chef integration
chef ai setup
```

The setup wizard will guide you through:
1. Entering your Azure OpenAI API key
2. Setting your Azure endpoint
3. Configuring the deployment name
4. Testing the connection

## Environment Variables

Chef AI Assistant can also be configured using environment variables:

```bash
export AZURE_OPENAI_API_KEY=your_api_key
export AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com
export AZURE_OPENAI_DEPLOYMENT_NAME=your_deployment_name
```

These can be set in your `.bashrc`, `.zshrc`, or through a `.env` file in your project directory.

## Troubleshooting Installation Issues

### Common Issues

1. **Ruby Version Incompatibility**
   
   If you encounter errors related to Ruby version, ensure you're using Ruby 2.7 or higher:
   ```bash
   ruby --version
   ```
   
   Consider using a Ruby version manager like RVM or rbenv if you need to upgrade.

2. **Gem Dependencies**
   
   If you encounter dependency issues:
   ```bash
   gem install chef-ai-assistant --force
   ```

3. **Permission Errors**
   
   If you face permission errors:
   ```bash
   sudo gem install chef-ai-assistant
   ```
   
   Or better, fix your Ruby installation permissions.

### Getting Help

If you continue to face installation issues:

1. Check the [Troubleshooting](troubleshooting.md) page
2. Open an issue on [GitHub](https://github.com/ashiqueps/chef-ai-assistant/issues)

## Next Steps

After installation:

1. Review the [Getting Started Guide](getting_started.md)
2. Learn the [Configuration Options](configuration.md)
3. Explore the [Command Reference](commands/index.md)
