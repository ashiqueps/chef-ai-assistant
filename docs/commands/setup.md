# Setup Command

The `setup` command helps you configure Chef AI Assistant with your Azure OpenAI credentials, establishing a secure connection between the tool and the AI service.

## Usage

```bash
# Standalone command
chef-ai setup [options]

# Integration with Chef tools
chef ai setup [options]
```

## Description

This command launches an interactive wizard that guides you through the process of configuring Chef AI Assistant with your Azure OpenAI credentials. It handles:

1. Collection of required API credentials
2. Secure storage of credentials
3. Validation of the connection to Azure OpenAI
4. Configuration of optional settings

## Options

| Option | Description |
|--------|-------------|
| `--force` | Overwrite existing credentials if they exist |
| `--help, -h` | Show help message |

## Interactive Setup Process

The setup command walks you through the following steps:

1. **API Key**: Enter your Azure OpenAI API key
2. **Azure Endpoint**: Enter your Azure OpenAI endpoint URL
3. **Deployment Name**: Enter your model deployment name
4. **API Version**: Confirm or modify the API version (defaults to `2023-05-15`)
5. **Connection Test**: Validates your credentials with a test request
6. **Configuration Storage**: Saves your credentials securely

## Example

```bash
$ chef-ai setup
# or with integration: chef ai setup

[⠦] Setting up Chef AI Assistant...
✓ Welcome to Chef AI Assistant Setup

Please provide your Azure OpenAI credentials:

API Key: ****************************************
Azure OpenAI Endpoint: https://my-resource.openai.azure.com
Deployment Name: gpt-4-deployment
API Version [2023-05-15]: 

Testing connection to Azure OpenAI...
Connection successful!

Your credentials have been saved to: ~/.chef/ai_credentials
✓ Setup complete. You can now use Chef AI Assistant.
```

## Security Considerations

- The setup command stores credentials in `~/.chef/ai_credentials` with strict permissions (0600)
- Only the current user can read or modify these credentials
- Credentials are stored in JSON format
- API keys and sensitive information are never logged

## Configuration File

The generated configuration file at `~/.chef/ai_credentials` contains:

```json
{
  "api_key": "your-encrypted-api-key",
  "azure_endpoint": "https://your-resource.openai.azure.com",
  "deployment_name": "your-deployment-name",
  "api_version": "2023-05-15"
}
```

## Updating Credentials

To update your credentials, run:

```bash
chef ai setup --force
```

This will overwrite your existing configuration with new values.

## Troubleshooting

If you encounter issues during setup:

1. **Connection Failures**: Verify your Azure OpenAI service is active and your credentials are correct
2. **Permission Issues**: Ensure you have write access to `~/.chef/` directory
3. **Invalid Credentials**: Double-check your API key, endpoint URL, and deployment name

For persistent issues, refer to the [Troubleshooting](../troubleshooting.md) guide.
