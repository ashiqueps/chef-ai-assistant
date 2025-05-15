# Command Generator

The `command` command translates natural language descriptions into proper Chef CLI commands, helping you find and use the right syntax without memorizing complex command structures.

## Usage

```bash
# Standalone command
chef-ai command "Description of what you want to do" [options]

# Integration with Chef tools
chef ai command "Description of what you want to do" [options]
```

## Description

This command uses AI to convert plain English descriptions into proper Chef commands with the correct syntax and options. It helps you:

1. Find the right command for a task
2. Use proper syntax and arguments
3. Understand what each part of the command does
4. Fill in placeholders with your specific values
5. Get command explanations and usage notes

## Options

| Option | Description |
|--------|-------------|
| `--temperature TEMP` | Set the response creativity (0.0-2.0, default: 0.7) |
| `--verbose, -v` | Show detailed response information |
| `--help, -h` | Show help message |

## Examples

### Basic Usage

```bash
# Generate a command to list nodes
chef-ai command "list all nodes"
# or: chef ai command "list all nodes"

# Generate a command to upload a cookbook
chef-ai command "upload my apache cookbook"
# or: chef ai command "upload my apache cookbook"

# Bootstrap a node
chef-ai command "bootstrap a windows server"
# or: chef ai command "bootstrap a windows server"
```

### Complex Commands

```bash
# Generate a command with multiple options
chef-ai command "search for nodes with role webserver in production environment"
# or: chef ai command "search for nodes with role webserver in production environment"

# Generate advanced knife commands
chef-ai command "create a data bag item with encrypted contents"
# or: chef ai command "create a data bag item with encrypted contents"

# Generate InSpec commands
chef-ai command "run inspec tests against a remote SSH target"
# or: chef ai command "run inspec tests against a remote SSH target"
```

## Interactive Process

The `command` command follows an interactive process:

1. **Analysis**: The AI examines your description to determine the appropriate Chef command
2. **Options**: Multiple command options may be presented if applicable
3. **Selection**: You choose which command variant best fits your needs
4. **Placeholders**: You're prompted to fill in placeholders like `<NODE_NAME>` with actual values
5. **Final Command**: The complete, ready-to-use command is presented

## Response Format

The interaction typically follows this pattern:

```
🔍 Processing:
  "bootstrap a windows node"
[...] Generating command...

🤖 Chef Command Generator:
To bootstrap a Windows node using Chef, you would typically use the `knife bootstrap windows winrm` command...

Available commands:
1. knife bootstrap windows winrm <NODE_IP> -x <USERNAME> -P <PASSWORD> --node-name <NODE_NAME> --run-list "<RUN_LIST>"
2. knife bootstrap windows winrm 192.168.1.100 -x Administrator -P 'SuperSecurePassword' --node-name webserver01 --run-list "recipe[iis]"

Enter number of command to use (or 0 to skip): 1
Enter value for NODE_IP: 192.168.1.156
Enter value for USERNAME: Administrator
Enter value for PASSWORD: SecurePassword
Enter value for NODE_NAME: win-node-1
Enter value for RUN_LIST: recipe[windows],recipe[iis]

============================================================
##  GENERATED CHEF COMMAND  ##
============================================================

    knife bootstrap windows winrm 192.168.1.156 -x Administrator -P SecurePassword --node-name win-node-1 --run-list "recipe[windows],recipe[iis]"
============================================================

✓ Just copy and paste this command into your terminal to use it.
```

## Supported Command Types

The command generator supports a wide range of Chef CLI tools:

- **knife**: For interacting with the Chef Server
- **chef**: Chef Infra Client and Workstation commands
- **inspec**: For InSpec compliance and security testing
- **hab**: For Habitat package and service management
- **chef-run**: For ad-hoc configuration tasks
- **kitchen**: For Test Kitchen testing commands
- **berks**: For Berkshelf dependency management

## Command Categories

The command generator can help with:

1. **Node Management**: Bootstrapping, searching, editing, deleting nodes
2. **Cookbook Operations**: Creating, uploading, downloading, versioning cookbooks
3. **Data Management**: Working with data bags, attributes, and environments
4. **Testing**: Running various types of tests and validations
5. **Infrastructure**: Managing infrastructure resources
6. **Compliance**: Running compliance checks and generating reports

## Use Cases

The `command` command is ideal for:

- Learning Chef CLI tools
- Finding the right syntax for complex commands
- Saving time on command construction
- Avoiding errors in command syntax
- Exploring available command options
- Converting task descriptions into executable commands

## See Also

- [ask](ask.md): For general Chef questions
- [generate](generate.md): For generating Chef code files
