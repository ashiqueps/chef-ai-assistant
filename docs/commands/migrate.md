# Migrate Command

The `migrate` command assists with migrating Chef code between different Chef versions, automating the identification and fixing of compatibility issues.

## Usage

```bash
# Standalone command
chef-ai migrate --from VERSION --to VERSION PATH [options]

# Integration with Chef tools
chef ai migrate --from VERSION --to VERSION PATH [options]
```

## Description

This command analyzes Chef code for compatibility issues when migrating between different Chef versions. It identifies deprecated features, syntax changes, and breaking changes, then provides solutions or automatically applies fixes. It can process individual files or entire directories.

## Options

| Option | Description |
|--------|-------------|
| `--from VERSION` | Source Chef version (e.g., 14) |
| `--to VERSION` | Target Chef version (e.g., 17) |
| `--output PATH` | Specify output directory for migrated files |
| `--scan-only` | Only scan for compatibility issues without making changes |
| `--temperature TEMP` | Set the response creativity (0.0-2.0) |
| `--verbose, -v` | Show detailed migration information |
| `--help, -h` | Show help message |

## Examples

### Basic Migration

```bash
# Migrate a single file
chef-ai migrate --from 14 --to 17 cookbooks/users/recipes/default.rb
# or: chef ai migrate --from 14 --to 17 cookbooks/users/recipes/default.rb

# Migrate an entire cookbook
chef-ai migrate --from 15 --to 18 cookbooks/apache
# or: chef ai migrate --from 15 --to 18 cookbooks/apache
```

### Migration Options

```bash
# Scan only without changes
chef-ai migrate --from 14 --to 17 cookbooks/nginx --scan-only
# or: chef ai migrate --from 14 --to 17 cookbooks/nginx --scan-only

# Migrate to a different output directory
chef-ai migrate --from 15 --to 18 cookbooks/database --output ./migrated_cookbooks
# or: chef ai migrate --from 15 --to 18 cookbooks/database --output ./migrated_cookbooks
```

## Migration Process

The `migrate` command follows these steps:

1. **Analysis**: Scans the code for version-specific issues
2. **Version Information**: Shows details about source and target Chef versions
3. **Issue Detection**: Lists files with compatibility problems
4. **Confirmation**: Asks for confirmation before making changes
5. **Migration**: Updates code to work with the target Chef version
6. **Backup**: Creates backups of original files
7. **Summary**: Provides a summary of changes made

## Response Format

A typical migration looks like this:

```
Chef Version Migration Overview:

Source: Chef 14 (Released: February 2018, EOL: April 2020)
Target: Chef 17 (Released: March 2021, EOL: April 2023)

Versions being skipped:
  Chef 15 (May 2019)
    • Chef Workstation replaces ChefDK
    • Chef InSpec integration
    • Target mode introduction
    • Multiple new resources

  Chef 16 (April 2020)
    • Unified Chef Infra Client
    • Improved resource subsystem
    • Many resources moved to core
    • Deprecation of legacy resources

New in Chef 17:
  • Ruby 3.0 support
  • New unified mode default for resources
  • Resource guard improvements
  • Compliance phase improvements

Do you want to proceed with the migration analysis? Yes
🔍 Analyzing Chef code for migration:
  Path: cookbooks/my_cookbook/recipes
  Migration: Chef 14 → Chef 17
  Mode: Full migration
  Found: 3 Chef files

Migration Analysis Results:
Files analyzed: 3
Files with issues: 2
Files without issues: 1

Files requiring migration:
  • default.rb
  • users.rb

Would you like to perform the migration? Yes

Creating backups in: cookbooks/my_cookbook/recipes/chef_migration_backup_20250513120113
  ✓ Migrated default.rb (1024 bytes)
  ✓ Migrated users.rb (895 bytes)

Migration Summary:
2 of 2 files migrated successfully
Original files backed up in: cookbooks/my_cookbook/recipes/chef_migration_backup_20250513120113
```

## Migration Capabilities

The `migrate` command can handle various types of changes:

1. **Deprecated Resources**: Updates or replaces deprecated resources
2. **Syntax Changes**: Modifies syntax to match new requirements
3. **Property Changes**: Updates resource properties that have changed
4. **API Changes**: Adapts to Chef Infra API changes
5. **Ruby Version Compatibility**: Updates Ruby syntax where needed
6. **Best Practices**: Implements version-specific best practices

## Supported Chef Versions

The migration command supports:

- Chef 12 to Chef 13+
- Chef 13 to Chef 14+
- Chef 14 to Chef 15+
- Chef 15 to Chef 16+
- Chef 16 to Chef 17+
- Chef 17 to Chef 18+

## Use Cases

The `migrate` command is ideal for:

- Updating legacy Chef code
- Preparing for Chef version upgrades
- Addressing deprecation warnings
- Learning about version differences
- Preventing breaking changes during upgrades
- Modernizing cookbook codebases

## Limitations

- Some complex migrations may require manual intervention
- Custom resources might need specialized attention
- Cookbooks with extensive Ruby logic may require additional review

## See Also

- [troubleshoot](troubleshoot.md): For diagnosing Chef-related issues
- [explain](explain.md): For analyzing Chef code structure
