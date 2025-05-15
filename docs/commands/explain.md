# Explain Command

The `explain` command analyzes Chef-related files or directories and provides human-readable explanations of their purpose, structure, and functionality.

## Usage

```bash
# Standalone command
chef-ai explain PATH [options]

# Integration with Chef tools
chef ai explain PATH [options]
```

## Description

This command examines Chef files such as recipes, cookbooks, resources, attributes files, or entire directories containing Chef code. It provides a detailed explanation in natural language, making it easier to understand:

1. What the code does
2. How it works
3. How different components interact
4. Any potential issues or improvements

## Options

| Option | Description |
|--------|-------------|
| `--temperature TEMP` | Set the response creativity (0.0-2.0, default: 0.7) |
| `--verbose, -v` | Show detailed analysis information |
| `--help, -h` | Show help message |

## Examples

### Explaining a Single File

```bash
# Explain a recipe
chef-ai explain cookbooks/apache/recipes/default.rb
# or: chef ai explain cookbooks/apache/recipes/default.rb

# Explain an attributes file
chef-ai explain cookbooks/users/attributes/default.rb
# or: chef ai explain cookbooks/users/attributes/default.rb

# Explain a resource
chef-ai explain cookbooks/database/resources/mysql_database.rb
# or: chef ai explain cookbooks/database/resources/mysql_database.rb
```

### Explaining Directories

```bash
# Explain an entire cookbook
chef-ai explain cookbooks/apache
# or: chef ai explain cookbooks/apache

# Explain just the recipes directory
chef-ai explain cookbooks/apache/recipes
# or: chef ai explain cookbooks/apache/recipes

# Explain multiple components
chef ai explain cookbooks/base_setup
```

### Using Options

```bash
# Get more creative explanations
chef ai explain Policyfile.rb --temperature 1.2

# See detailed analysis, including token counts
chef ai explain metadata.rb --verbose
```

## Response Format

The `explain` command responses follow this structure:

```
💼 Analyzing:
  path/to/chef/file.rb
[...] Consulting AI assistant...

🤖 AI Explanation:
Detailed explanation of the file or directory, which typically includes:

Purpose:
- What the file/directory is designed to accomplish
- Its role in the wider Chef ecosystem

Structure Analysis:
- Breakdown of key components
- How different parts work together
- Important code sections explained

For cookbooks, might include:
- Resources used
- Attributes and their purpose
- Recipe flow and execution order
- Dependencies and related components

Potential Issues:
- Style concerns
- Deprecated syntax
- Performance considerations
- Security considerations

Best Practices:
- Suggestions for improvement
- Links to relevant documentation
- Alternative approaches
```

## Supported File Types

The `explain` command can analyze:

- Recipes (`.rb`)
- Resources (in `resources/` directory)
- Attributes files (in `attributes/` directory)
- Metadata files (`metadata.rb`)
- Policy files (`Policyfile.rb`)
- InSpec profiles and controls
- Habitat plans (`plan.sh`)
- Kitchen configuration (`.kitchen.yml`)
- Berkshelf files (`Berksfile`)
- Knife configuration (`knife.rb`)
- Client configuration (`client.rb`)
- Server configuration (`server.rb`)

For directories, it examines the structure and relationships between files.

## Use Cases

The `explain` command is ideal for:

- Onboarding new team members to a Chef codebase
- Understanding legacy Chef code
- Reviewing cookbooks before implementation
- Learning Chef by examining examples
- Documenting existing Chef code
- Preparing for refactoring or updates

## See Also

- [ask](ask.md): For general Chef questions
- [troubleshoot](troubleshoot.md): For diagnosing Chef-related errors
