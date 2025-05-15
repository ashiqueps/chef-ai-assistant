# Generate Command

The `generate` command creates Chef ecosystem files from natural language descriptions, automating the creation of cookbooks, recipes, resources, and more.

## Usage

```bash
# Standalone command
chef-ai generate "Description of what to create" [options]

# Integration with Chef tools
chef ai generate "Description of what to create" [options]
```

## Description

This command leverages AI to translate natural language descriptions into properly structured Chef code. It can generate complete cookbooks, individual recipes, custom resources, attributes files, and more. The generated code follows Chef best practices and includes appropriate documentation.

## Options

| Option | Description |
|--------|-------------|
| `--output PATH, -o PATH` | Specify output directory (default: current directory) |
| `--temperature TEMP` | Set the creativity level (0.0-2.0, default: 0.7) |
| `--verbose, -v` | Show detailed generation information |
| `--help, -h` | Show help message |

## Examples

### Generating Cookbooks

```bash
# Generate a complete cookbook
chef-ai generate "Create a cookbook for managing PostgreSQL databases"
# or: chef ai generate "Create a cookbook for managing PostgreSQL databases"

# Generate a cookbook with specific features
chef-ai generate "Create a cookbook for Apache that handles virtual hosts and SSL"
# or: chef ai generate "Create a cookbook for Apache that handles virtual hosts and SSL"

# Specify output location
chef-ai generate "Create a MySQL cookbook" --output ./my_cookbooks
# or: chef ai generate "Create a MySQL cookbook" --output ./my_cookbooks
```

### Generating Individual Files

```bash
# Generate a specific recipe
chef-ai generate "Write a recipe that configures Nginx as a reverse proxy"
# or: chef ai generate "Write a recipe that configures Nginx as a reverse proxy"

# Generate a custom resource
chef-ai generate "Create a custom resource for managing Java versions"
# or: chef ai generate "Create a custom resource for managing Java versions"

# Generate attributes file
chef ai generate "Create attributes file for a web server cookbook with configurable ports"
```

### Generating Special Components

```bash
# Generate an InSpec profile
chef ai generate "Create an InSpec profile to audit SSH configuration"

# Generate a Habitat plan
chef ai generate "Create a Habitat plan for packaging a Node.js application"

# Generate a Policyfile
chef ai generate "Create a Policyfile for a web application environment"
```

## Response Format

The `generate` command shows progress and results as follows:

```
🔍 Processing:
  "Create a cookbook for managing users"
[...] Generating files...

🤖 Chef Generation Summary:
I'll create a 'users_cookbook' that manages system users with the following files:

├── metadata.rb
├── README.md
├── attributes/
│   └── default.rb
├── recipes/
│   ├── default.rb
│   ├── create.rb
│   └── remove.rb
├── templates/
│   └── user_profile.erb
└── test/
    └── integration/
        └── default/
            └── default_test.rb

Generating files... 

✅ Successfully generated:
metadata.rb (576 bytes)
README.md (1.2 KB)
attributes/default.rb (486 bytes)
recipes/default.rb (312 bytes)
recipes/create.rb (964 bytes)
recipes/remove.rb (482 bytes)
templates/user_profile.erb (125 bytes)
test/integration/default/default_test.rb (354 bytes)

This cookbook:
- Creates and manages system users across your infrastructure
- Allows customizing user attributes through node attributes
- Supports creating, modifying and removing users
- Includes test-kitchen integration tests

To use this cookbook:
1. Modify attributes/default.rb to configure your users
2. Include the default recipe in your run list
3. For advanced usage, include create or remove recipes directly
```

## Generated Components

The `generate` command can create:

1. **Cookbooks**: Complete cookbook structure
   - metadata.rb with proper dependencies
   - README.md with usage instructions
   - Recipes with well-structured code
   - Attributes with default values
   - Resources when needed
   - Templates and files
   - Test kitchen configuration
   - ChefSpec and InSpec tests

2. **Individual Components**:
   - Recipes with best practices implementation
   - Custom resources with actions and properties
   - Attributes files with documentation
   - Libraries with helper methods
   - Templates with ERB syntax
   - Test files for verification

## Code Quality

Generated code follows these principles:

- Proper Chef style and idioms
- Clear commenting and documentation
- Appropriate error handling
- Idempotent resource usage
- Platform awareness when relevant
- Security best practices
- Performance considerations

## Use Cases

The `generate` command is ideal for:

- Quickly bootstrapping new cookbooks
- Creating boilerplate code for common patterns
- Learning proper Chef coding style
- Prototyping solutions
- Generating standard components with less effort
- Creating starting points for custom development

## Limitations

- Generated code may require customization for specific environments
- Complex infrastructure requirements might need manual adjustments
- Integration with existing code may require additional modifications

## See Also

- [command](command.md): For generating Chef CLI commands
- [explain](explain.md): For analyzing existing Chef code
