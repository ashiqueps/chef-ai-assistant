# Commands Reference

Chef AI Assistant provides a variety of commands to help you interact with the Chef ecosystem. This page provides an overview of all available commands and links to detailed documentation for each.

## Available Commands

| Command | Description | Documentation |
|---------|-------------|---------------|
| `chef ai setup` | Configure Chef AI Assistant credentials | [Setup](setup.md) |
| `chef ai ask` | Ask questions about Chef | [Ask](ask.md) |
| `chef ai explain` | Get explanations of Chef files and directories | [Explain](explain.md) |
| `chef ai generate` | Generate Chef ecosystem files from descriptions | [Generate](generate.md) |
| `chef ai command` | Generate Chef commands from natural language | [Command](command.md) |
| `chef ai troubleshoot` | Diagnose and fix Chef-related issues | [Troubleshoot](troubleshoot.md) |
| `chef ai migrate` | Assist with migrations between Chef versions | [Migrate](migrate.md) |

## General Command Options

These options are available across multiple Chef AI Assistant commands:

| Option | Description | Example |
|--------|-------------|---------|
| `--help, -h` | Display help for a command | `chef ai ask --help` |
| `--temperature TEMP` | Adjust response creativity (0.0-2.0) | `chef ai ask --temperature 0.8` |
| `--verbose, -v` | Show detailed output | `chef ai explain --verbose` |

## Command Usage Patterns

Chef AI Assistant commands follow consistent usage patterns:

### Help

Get help for any command:

```bash
chef ai --help
chef ai COMMAND --help
```

### Command with Arguments

Most commands accept arguments directly:

```bash
chef ai ask "How do I write a recipe for Apache?"
chef ai explain path/to/cookbook
```

### Command with Options

Options can be combined with arguments:

```bash
chef ai generate "Create a cookbook for MongoDB" --output ./cookbooks --temperature 0.8
chef ai troubleshoot "Error loading cookbook" --verbose
```

## Command Output

Most Chef AI Assistant commands format their output with:

1. A progress indicator
2. The response from the AI assistant
3. Any additional information or follow-up actions

For example:

```
🔍 Processing:
  "How do I write a recipe for Apache?"
[...] Consulting AI assistant...

🤖 AI Response:
To write a recipe for installing and configuring Apache...
```

## Command Execution Environment

Commands operate within the current directory context. For file-related commands like `explain` and `migrate`, both relative and absolute paths are supported.

For specific details on each command, follow the links in the Available Commands table above.
