# Troubleshoot Command

The `troubleshoot` command helps diagnose and fix Chef-related issues by analyzing error messages, log files, and configuration files.

## Usage

```bash
chef ai troubleshoot "ERROR_MESSAGE" [options]
chef ai troubleshoot path/to/error.log [options]
```

## Description

This command uses AI to analyze Chef error messages, log files, or configuration files to identify the root cause of problems and provide step-by-step solutions. It can process direct error messages, examine log files for patterns, and analyze Chef configuration for issues.

## Options

| Option | Description |
|--------|-------------|
| `--logs PATH` | Provide a path to Chef logs for analysis |
| `--config PATH` | Provide a path to Chef config file for analysis |
| `--temperature TEMP` | Set the response creativity (0.0-2.0) |
| `--verbose, -v` | Show detailed troubleshooting information |
| `--help, -h` | Show help message |

## Examples

### Basic Troubleshooting

```bash
# Troubleshoot an error message
chef ai troubleshoot "ERROR: Connection refused connecting to localhost:8889"

# Troubleshoot a log file
chef ai troubleshoot /var/log/chef/client.log
```

### Advanced Troubleshooting

```bash
# Provide both logs and configuration
chef ai troubleshoot --logs /var/log/chef/client.log --config /etc/chef/client.rb

# Troubleshoot with specific error message and logs
chef ai troubleshoot "Error executing action" --logs /var/log/chef/client.log
```

## Response Format

Troubleshooting results are formatted as follows:

```
🔍 Analyzing issue:
  "ERROR: Connection refused connecting to localhost:8889"
[...] Consulting AI assistant...

🔧 Troubleshooting Diagnosis:

This error occurs when Chef client is unable to connect to a service on port 8889 on localhost.

----------------------------------------
Solution:

Step 1: Verify if the service is running
Run the following command to check if anything is listening on port 8889:
  sudo lsof -i :8889

Step 2: Check firewall settings
Ensure that local connections on port 8889 are allowed:
  sudo iptables -L | grep 8889

Step 3: Examine Chef configuration
Make sure your Chef configuration is pointing to the correct endpoint and port.
Check your client.rb or knife.rb for any incorrect settings.

Step 4: Restart the service
If the service should be running on this port, try restarting it:
  sudo systemctl restart chef-service-name

Warning: Connection refused errors often indicate that a required service is not running or is misconfigured. Check the service's logs for additional clues.
```

## Analysis Capabilities

The troubleshoot command can analyze:

1. **Error Messages**: Direct chef-client, knife, kitchen, or inspec errors
2. **Log Files**: Chef client logs, server logs, and other Chef tool logs
3. **Configuration Files**: client.rb, server.rb, knife.rb, kitchen.yml, etc.
4. **Combinations**: Error messages with supporting log/config context

## Issue Categories

The troubleshooter can diagnose issues related to:

- **Connectivity**: Network-related failures, API connectivity
- **Authentication**: Authorization errors, API key issues
- **Configuration**: Misconfigured Chef settings
- **Resources**: Failed resource execution, incorrect resource syntax
- **Dependencies**: Missing cookbooks, missing gems
- **Syntax**: Ruby syntax errors, Chef DSL problems
- **Compatibility**: Version compatibility issues
- **Performance**: Slow operations, timeout issues
- **System**: File system permissions, disk space problems

## Solution Format

Solutions typically include:

1. **Root Cause Analysis**: Explanation of what's causing the issue
2. **Step-by-Step Instructions**: Clear steps to resolve the problem
3. **Verification Commands**: Commands to verify if the solution worked
4. **Alternative Approaches**: Optional alternative solutions when applicable
5. **Prevention Tips**: How to avoid similar issues in the future

## Use Cases

The `troubleshoot` command is ideal for:

- Diagnosing Chef convergence failures
- Resolving knife command errors
- Fixing Test Kitchen issues
- Solving InSpec execution problems
- Understanding complex error messages
- Identifying configuration problems
- Getting unstuck during Chef operations

## Limitations

- Some issues may require additional system information
- Hardware-specific problems might need manual diagnosis
- Custom or third-party cookbook issues may need specialized knowledge

## See Also

- [migrate](migrate.md): For fixing Chef version compatibility issues
- [explain](explain.md): For understanding Chef code structure
