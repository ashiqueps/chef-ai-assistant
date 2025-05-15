# Ask Command

The `ask` command allows you to ask questions about Chef in natural language and receive detailed, contextual responses from the AI assistant.

## Usage

```bash
# Standalone command
chef-ai ask "Your question about Chef" [options]

# Integration with Chef tools
chef ai ask "Your question about Chef" [options]
```

## Description

This command enables natural language interaction with the Chef AI Assistant. It accepts questions related to Chef concepts, syntax, best practices, or specific tools within the Chef ecosystem. Based on the integration context, the AI will focus its responses on the relevant Chef tool (e.g., Chef Infra, InSpec, Habitat).

## Options

| Option | Description |
|--------|-------------|
| `--temperature TEMP` | Set the response creativity (0.0-2.0, default: 0.7) |
| `--system PROMPT` | Set a custom system prompt for the AI |
| `--verbose, -v` | Show detailed response information |
| `--help, -h` | Show help message |

## Examples

### Basic Questions

```bash
# Ask about a Chef concept - standalone command
chef-ai ask "What is a recipe in Chef?"
# or with integration
chef ai ask "What is a recipe in Chef?"

# Ask about best practices
chef-ai ask "What's the best way to handle secrets in Chef?"
# or: chef ai ask "What's the best way to handle secrets in Chef?"

# Ask about syntax
chef-ai ask "How do I write a Chef resource for installing a package?"
# or: chef ai ask "How do I write a Chef resource for installing a package?"
```

### Questions with Context Awareness

When integrated with specific Chef tools:

```bash
# When used with knife
knife ai ask "How do I bootstrap a node?"

# When used with InSpec
inspec ai ask "How do I write a control to check file permissions?"
```

### Using Options

```bash
# More creative responses
chef ai ask "Ways to organize my cookbooks" --temperature 1.2

# Custom system prompt
chef ai ask "Explain resources" --system "You are a Chef teacher for beginners"

# Verbose output with token usage
chef ai ask "What are data bags?" --verbose
```

## Response Format

The `ask` command responses follow this structure:

```
🔍 Processing:
  "Your question about Chef"
[...] Consulting AI assistant...

🤖 AI Response:
Detailed answer to your question, which may include:

- Explanations of Chef concepts
- Code examples with syntax highlighting
- Best practices and recommendations
- References to official documentation
- Step-by-step instructions

Additional context or caveats may be included depending on the question.
```

## Use Cases

The `ask` command is ideal for:

- Learning Chef concepts as a beginner
- Refreshing knowledge on specific features
- Understanding best practices
- Solving common Chef problems
- Getting syntax guidance
- Finding alternative approaches

## Limitations

- Questions must relate to Chef and the current integration context (in strict mode)
- The AI may not have knowledge of Chef features released after its training cutoff
- For specific file or error analysis, the `explain` or `troubleshoot` commands may be more appropriate

## Related Commands

- [explain](explain.md): For analyzing specific Chef files
- [troubleshoot](troubleshoot.md): For diagnosing and fixing Chef-related issues

## See Also

- [Context Awareness](../context_awareness.md): Learn about strict vs. relaxed context modes
