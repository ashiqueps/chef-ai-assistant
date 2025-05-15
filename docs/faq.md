# Frequently Asked Questions

This page addresses common questions about Chef AI Assistant.

## General Questions

### What is Chef AI Assistant?

Chef AI Assistant is a Ruby gem that provides AI-powered capabilities for Chef. It helps with explaining Chef code, generating Chef commands, troubleshooting issues, and answering questions about Chef.

### What Chef tools does Chef AI Assistant work with?

Chef AI Assistant works with the entire Chef ecosystem, including Chef Infra, InSpec, Habitat, Test Kitchen, Knife, and more. It can be integrated with any Chef-related Ruby gem to provide AI capabilities through their CLI.

### How is Chef AI Assistant different from regular documentation?

Unlike static documentation, Chef AI Assistant:
- Provides dynamic, context-aware answers to your specific questions
- Generates custom code and commands tailored to your needs
- Troubleshoots your specific errors and issues
- Analyzes your existing code and explains it in detail
- Adapts to different Chef tools and versions

### Do I need an internet connection to use Chef AI Assistant?

Yes, Chef AI Assistant requires an internet connection to communicate with Azure OpenAI services.

## Setup and Configuration

### How do I install Chef AI Assistant?

Install it using RubyGems:
```bash
gem install chef-ai-assistant
```

For more detailed instructions, see the [Installation Guide](installation.md).

### What credentials do I need to use Chef AI Assistant?

You need:
1. An Azure OpenAI API key
2. An Azure OpenAI endpoint URL
3. A deployment name for your model

### How do I configure my credentials?

Run the setup command:
```bash
chef ai setup
```

This will guide you through entering and saving your credentials securely.

### Where are my credentials stored?

Credentials are stored in `~/.chef/ai_credentials` with read/write permissions restricted to your user account only (`0600` permissions).

### Can I use environment variables instead?

Yes, you can set these environment variables:
```bash
export AZURE_OPENAI_API_KEY=your_api_key
export AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com
export AZURE_OPENAI_DEPLOYMENT_NAME=your_deployment_name
```

### What Azure OpenAI model should I use?

We recommend using GPT-4 or GPT-3.5 Turbo for best results. Your Azure OpenAI deployment should use one of these models.

## Commands and Usage

### What commands are available?

The main commands are:
- `setup`: Configure credentials
- `ask`: Ask questions about Chef
- `explain`: Get explanations of Chef code
- `generate`: Generate Chef code from descriptions
- `command`: Generate Chef CLI commands
- `troubleshoot`: Diagnose Chef issues
- `migrate`: Help with Chef version migrations

### How do I ask a question?

Use the ask command:
```bash
chef ai ask "How do I write a recipe that installs nginx?"
```

### Can I get explanations for existing code?

Yes, use the explain command:
```bash
chef ai explain path/to/cookbook
```

### How do I troubleshoot errors?

Use the troubleshoot command:
```bash
chef ai troubleshoot "Error message or description"
```

Or point it to a log file:
```bash
chef ai troubleshoot /var/log/chef/client.log
```

## Advanced Usage

### What is context awareness?

Context awareness means Chef AI Assistant knows which Chef tool it's integrated with (Chef Infra, InSpec, etc.) and tailors its responses to that context.

### What's the difference between strict and relaxed context modes?

- **Strict Mode**: The AI only answers questions specific to the current tool context
- **Relaxed Mode**: The AI answers questions about any Chef tool, regardless of context

### How do I change the temperature setting?

Use the `--temperature` option:
```bash
chef ai ask "How do I write a recipe?" --temperature 0.9
```

Higher values (up to 2.0) give more creative responses, while lower values give more focused, deterministic responses.

### Can I use custom system prompts?

Yes, use the `--system` option:
```bash
chef ai ask "How do I write a recipe?" --system "You are a Chef expert focusing on security best practices"
```

### Can I integrate Chef AI Assistant with my own gem?

Yes, see the [Integration Guide](integration_guide.md) for instructions on integrating with your own Ruby gems.

## Troubleshooting

### Why am I getting credential errors?

Make sure you've run `chef ai setup` or set the required environment variables. Verify your Azure OpenAI service is active and your credentials are correct.

### How do I update my credentials?

Run:
```bash
chef ai setup --force
```

### The AI doesn't understand my questions about another Chef tool

This might be due to strict context mode. Try:
```bash
export CHEF_AI_STRICT_CONTEXT=false
```

Or see [Context Awareness](context_awareness.md) for more information.

### How can I report issues or suggest improvements?

Submit issues on our [GitHub repository](https://github.com/ashiqueps/chef-ai-assistant/issues).

## Security

### Is it safe to share my code with Chef AI Assistant?

Chef AI Assistant processes your code through Azure OpenAI, which has data handling policies in place. However:
- Don't share sensitive information like passwords or keys
- Be cautious with proprietary code
- Review Azure OpenAI's data retention policies

### Does Chef AI Assistant store my queries or code?

Chef AI Assistant itself doesn't store your queries or code beyond the current session. However, your data is processed through Azure OpenAI, which may have its own data retention policies.

### How secure are my API credentials?

Your credentials are stored with `0600` permissions, meaning only your user account can read or write them.
