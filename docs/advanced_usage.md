# Advanced Usage

This guide covers advanced usage patterns and techniques for Chef AI Assistant, helping you get the most out of its capabilities.

## Customizing System Prompts

You can provide custom system prompts to change how the AI responds:

```bash
# Using a custom system prompt with the ask command (standalone binary)
chef-ai ask "How do I use search?" --system "You are a Chef expert who gives very concise answers with code examples."
# Or with Chef integration
chef ai ask "How do I use search?" --system "You are a Chef expert who gives very concise answers with code examples."

# Using a custom system prompt with explain (standalone binary)
chef-ai explain metadata.rb --system "Explain this as if to a complete beginner"
# Or with Chef integration
chef ai explain metadata.rb --system "Explain this as if to a complete beginner"
```

## Chaining Commands with Shell Pipes

Many Chef AI Assistant commands work well with shell pipes and redirections:

```bash
# Pipe content to the explain command (standalone binary)
cat recipes/default.rb | chef-ai explain
# Or with Chef integration
cat recipes/default.rb | chef ai explain

# Pipe error output to troubleshoot (standalone binary)
chef-client --local-mode 2>&1 | chef-ai troubleshoot
# Or with Chef integration
chef-client --local-mode 2>&1 | chef ai troubleshoot

# Save AI output to a file (standalone binary)
chef-ai generate "cookbook for nginx" > nginx_generation_plan.txt
# Or with Chef integration
chef ai generate "cookbook for nginx" > nginx_generation_plan.txt
```

## Batch Processing

For operations on multiple files or queries:

```bash
# Process multiple files with a loop (standalone binary)
for file in cookbooks/base/recipes/*.rb; do
  chef-ai explain "$file" --verbose
done

# Or with Chef integration
for file in cookbooks/base/recipes/*.rb; do
  chef ai explain "$file" --verbose
done

# Batch migration of multiple cookbooks (standalone binary)
for cb in cookbooks/*; do
  if [ -d "$cb" ]; then
    chef-ai migrate --from 14 --to 17 "$cb" --scan-only
  fi
done

# Or with Chef integration
for cb in cookbooks/*; do
  if [ -d "$cb" ]; then
    chef ai migrate --from 14 --to 17 "$cb" --scan-only
  fi
done
```

## Working with Environment Variables

Advanced configuration through environment variables:

```bash
# Set temperature for a single session
export CHEF_AI_TEMPERATURE=0.9
chef-ai ask "What's a good cookbook structure?"  # Standalone binary
# Or: chef ai ask "What's a good cookbook structure?"  # With Chef integration

# Enable detailed output for debugging
export CHEF_AI_VERBOSE=true
chef-ai troubleshoot "Error in resource"  # Standalone binary
# Or: chef ai troubleshoot "Error in resource"  # With Chef integration

# Turn off strict context mode temporarily
export CHEF_AI_STRICT_CONTEXT=false
inspec ai ask "How do I write a Chef recipe?"  # With InSpec integration
# Or use standalone: chef-ai ask "How do I write a Chef recipe?"
```

## Scripting and Automation

Incorporate Chef AI Assistant into scripts:

```bash
#!/bin/bash
# Example: Automated cookbook analysis script

# Set up variables
COOKBOOK_DIR="./cookbooks"
REPORT_DIR="./reports"
mkdir -p "$REPORT_DIR"

# Loop through cookbooks and analyze
for cookbook in "$COOKBOOK_DIR"/*; do
  if [ -d "$cookbook" ]; then
    cb_name=$(basename "$cookbook")
    echo "Analyzing $cb_name..."
    
    # Generate report using AI explain
    chef ai explain "$cookbook" --verbose > "$REPORT_DIR/${cb_name}_analysis.md"
    
    # Check for migration issues
    chef ai migrate --from 14 --to 17 "$cookbook" --scan-only > "$REPORT_DIR/${cb_name}_migration.md"
  fi
done

echo "Analysis complete. Reports in $REPORT_DIR"
```

## Custom Configuration Files

Create a custom configuration file at `~/.chef/ai_config.json`:

```json
{
  "api_key": "your-azure-openai-api-key",
  "api_version": "2023-05-15",
  "azure_endpoint": "https://your-resource-name.openai.azure.com",
  "deployment_name": "your-model-deployment-name",
  "strict_context_aware": true,
  "default_temperature": 0.8
}
```

## Working with Multiple Models

If you have access to multiple Azure OpenAI deployments:

```bash
# Switch between models using environment variables
export AZURE_OPENAI_DEPLOYMENT_NAME="gpt-4-deployment"
chef ai generate "complex nginx cookbook"

export AZURE_OPENAI_DEPLOYMENT_NAME="gpt-35-turbo-deployment"
chef ai ask "basic chef concepts"
```

## API Integration

Use Chef AI Assistant programmatically in your Ruby code:

```ruby
require 'chef-ai-assistant'

# Configure the client
ChefAiAssistant.configure do |config|
  config.api_key = ENV['AZURE_OPENAI_API_KEY']
  config.azure_endpoint = ENV['AZURE_OPENAI_ENDPOINT']
  config.deployment_name = ENV['AZURE_OPENAI_DEPLOYMENT_NAME']
end

# Get a client instance
client = ChefAiAssistant.openai_client

# Make a direct API call
response = client.chat(
  "Explain Chef resources",
  {
    temperature: 0.7,
    max_tokens: 1000
  }
)

puts response.dig("choices", 0, "message", "content")
```

## Debug Mode

Enable debug output for troubleshooting:

```bash
# Enable debug mode for all commands
export DEBUG=true
chef ai ask "How do templates work?"

# or just for a single command
DEBUG=true chef ai troubleshoot "Error executing action"
```

## Advanced Command Options

Some lesser-known but powerful command options:

```bash
# Generate code with higher creativity
chef ai generate "MongoDB cookbook" --temperature 1.2

# Perform migration analysis only on specific files
chef ai migrate --from 15 --to 18 cookbooks/mysql/recipes/default.rb cookbooks/mysql/recipes/server.rb

# Get detailed token usage statistics
chef ai explain complex_cookbook.rb --verbose
```

## Working with Large Codebases

For large cookbooks or repositories:

```bash
# Analyze cookbook structure first
chef ai explain cookbooks/large_cookbook --verbose > structure_analysis.md

# Then target specific components
chef ai explain cookbooks/large_cookbook/recipes/default.rb
chef ai explain cookbooks/large_cookbook/resources

# Divide migration into manageable chunks
chef ai migrate --from 14 --to 17 cookbooks/large_cookbook/recipes
chef ai migrate --from 14 --to 17 cookbooks/large_cookbook/resources
```

## Custom Initialization Scripts

Create init scripts that set up your preferred configuration:

```bash
#!/bin/bash
# chef-ai-init.sh

# Configure environment
export AZURE_OPENAI_API_KEY="your-key-here"
export AZURE_OPENAI_ENDPOINT="your-endpoint"
export AZURE_OPENAI_DEPLOYMENT_NAME="your-deployment"
export CHEF_AI_TEMPERATURE=0.8
export CHEF_AI_STRICT_CONTEXT=true

# Add chef-ai shortcuts to your session (using standalone binary for better performance)
alias cask="chef-ai ask"        # Using standalone binary
alias cexplain="chef-ai explain"    # Using standalone binary
alias ctrouble="chef-ai troubleshoot"  # Using standalone binary
alias cgen="chef-ai generate"      # Using standalone binary
alias ccmd="chef-ai command"       # Using standalone binary

echo "Chef AI Assistant environment configured!"
```

Source this script when needed: `source chef-ai-init.sh`

## Working with Context Awareness Modes

Configure context awareness modes for different use cases:

```bash
# Enable relaxed context mode for a session
export CHEF_AI_STRICT_CONTEXT=false
chef-ai ask "Tell me about Test Kitchen"  # Standalone binary
# Or: chef ai ask "Tell me about Test Kitchen"  # With Chef integration

# For a single command with relaxed context
CHEF_AI_STRICT_CONTEXT=false chef-ai ask "How do I use Foodcritic?"  # Standalone binary
# Or: CHEF_AI_STRICT_CONTEXT=false chef ai ask "How do I use Foodcritic?"  # With Chef integration

# Force strict context enforcement in integrated tools
export CHEF_AI_STRICT_CONTEXT=true
knife ai ask "How do I use knife?"  # Will only answer knife-related questions
```

## Command Chaining for Complex Workflows

Chain AI commands for sophisticated automation:

```bash
# Generate a cookbook, then explain it (standalone binary)
chef-ai generate "MySQL monitoring cookbook" | tee cookbook_plan.txt && \
chef-ai explain cookbooks/mysql_monitoring

# Analyze cookbook, then create migration plan (standalone binary)
chef-ai explain cookbooks/legacy --verbose > analysis.md && \
chef-ai migrate --from 14 --to 17 cookbooks/legacy --scan-only > migration_plan.md

# Generate examples, then check for issues (standalone binary)
chef-ai generate "custom resources for Apache" > resources.rb && \
chef-ai troubleshoot resources.rb
```

## Advanced Integration with Ruby Scripts

More complex Ruby integration examples:

```ruby
require 'chef-ai-assistant'
require 'json'

# Initialize with custom configuration
ChefAiAssistant.configure do |config|
  config.api_key = ENV['AZURE_OPENAI_API_KEY']
  config.azure_endpoint = ENV['AZURE_OPENAI_ENDPOINT']
  config.deployment_name = ENV['AZURE_OPENAI_DEPLOYMENT_NAME']
  config.strict_context_aware = false
  config.default_temperature = 0.5
end

# Create a client with custom options
client = ChefAiAssistant.openai_client

# Advanced API usage with structured request
response = client.chat(
  nil,
  {
    messages: [
      { role: "system", content: "You are a Chef expert focusing on security best practices." },
      { role: "user", content: "What's the best way to handle secrets in Chef?" }
    ],
    temperature: 0.3,
    max_tokens: 1500,
    top_p: 0.95,
    frequency_penalty: 0.0,
    presence_penalty: 0.0
  }
)

# Process the response as JSON
response_content = response.dig("choices", 0, "message", "content")
puts "Security Advice: #{response_content}"

# Save the response to a file
File.write('security_practices.md', response_content)
```

## Performance Optimization Techniques

Fine-tune performance for different scenarios:

```bash
# For quick answers with minimal token usage
export CHEF_AI_TEMPERATURE=0.3
export CHEF_AI_MAX_TOKENS=800
chef-ai ask "What is a recipe?"   # Standalone binary
# Or: chef ai ask "What is a recipe?"   # With Chef integration

# For detailed, thorough responses
export CHEF_AI_TEMPERATURE=0.7
export CHEF_AI_MAX_TOKENS=2000
chef-ai explain complex_cookbook.rb   # Standalone binary
# Or: chef ai explain complex_cookbook.rb   # With Chef integration

# For creative code generation
export CHEF_AI_TEMPERATURE=1.0
export CHEF_AI_MAX_TOKENS=3000
chef-ai generate "innovative ways to implement node bootstrapping"   # Standalone binary
# Or: chef ai generate "innovative ways to implement node bootstrapping"   # With Chef integration
```

## Conditional Processing with Exit Codes

Using exit codes for conditional workflows:

```bash
#!/bin/bash
# Example: Conditional cookbook processing workflow

# Try to explain the cookbook (using standalone binary for better performance)
chef-ai explain cookbooks/problematic_cookbook --verbose
if [ $? -eq 0 ]; then
  echo "Cookbook analysis successful, proceeding with migration"
  chef-ai migrate --from 14 --to 17 cookbooks/problematic_cookbook
else
  echo "Cookbook analysis failed, attempting troubleshooting"
  chef-ai troubleshoot cookbooks/problematic_cookbook > troubleshoot_report.md
fi
```

## Creating Custom AI Workflows

Develop specialized workflows for common tasks:

```bash
#!/bin/bash
# cookbook_analyzer.sh - Advanced cookbook analysis tool

COOKBOOK_PATH="$1"
OUTPUT_DIR="${2:-./analysis}"
mkdir -p "$OUTPUT_DIR"

# Display usage if no path provided
if [ -z "$COOKBOOK_PATH" ]; then
  echo "Usage: cookbook_analyzer.sh PATH/TO/COOKBOOK [OUTPUT_DIR]"
  exit 1
fi

echo "Analyzing cookbook: $COOKBOOK_PATH"
echo "Output directory: $OUTPUT_DIR"

# Comprehensive analysis with multiple AI commands
echo "1. Performing code explanation..."
chef ai explain "$COOKBOOK_PATH" --verbose > "$OUTPUT_DIR/explanation.md"

echo "2. Checking for best practices..."
chef ai ask "Analyze $COOKBOOK_PATH for Chef best practices" \
  --system "You are a Chef expert that evaluates cookbooks against best practices" \
  > "$OUTPUT_DIR/best_practices.md"

echo "3. Checking for migration issues..."
chef ai migrate --from 14 --to 17 "$COOKBOOK_PATH" --scan-only > "$OUTPUT_DIR/migration_issues.md"

echo "4. Generating test coverage report..."
chef ai ask "What test coverage should $COOKBOOK_PATH have?" \
  --system "You are a Chef testing expert" > "$OUTPUT_DIR/test_coverage.md"

echo "5. Creating summary report..."
echo "# Cookbook Analysis Summary for $(basename "$COOKBOOK_PATH")" > "$OUTPUT_DIR/summary.md"
echo "Analysis date: $(date)" >> "$OUTPUT_DIR/summary.md"
echo "" >> "$OUTPUT_DIR/summary.md"

# Extract key findings from each report
echo "## Key Findings" >> "$OUTPUT_DIR/summary.md"
chef ai ask "Summarize these analysis results in bullet points:" \
  --system "Create a concise executive summary with the most important points" \
  < <(cat "$OUTPUT_DIR"/*.md) >> "$OUTPUT_DIR/summary.md"

echo "Analysis complete! Summary available at: $OUTPUT_DIR/summary.md"
```

## Advanced CI/CD Integration

Incorporate Chef AI Assistant in CI/CD pipelines:

```bash
#!/bin/bash
# chef_ai_ci.sh - CI integration script for Chef AI Assistant

# Set environment
export CHEF_AI_VERBOSE=true
export CHEF_AI_STRICT_CONTEXT=true

# Step 1: Analyze changes
echo "Analyzing cookbook changes..."
git diff --name-only HEAD~1 | grep -E "\.rb$" | xargs -I{} chef ai explain {} > analysis.log

# Step 2: Check for potential issues
echo "Checking for potential issues..."
cat analysis.log | chef ai ask "Identify any potential issues in this analysis" > issues.md

# Step 3: Run migration check on changed files
echo "Running migration compatibility check..."
git diff --name-only HEAD~1 | grep -E "\.rb$" | xargs -I{} \
  chef ai migrate --from 14 --to 17 {} --scan-only > migration.log

# Step 4: Generate test suggestions
echo "Generating test suggestions..."
git diff --name-only HEAD~1 | grep -E "recipes\/.*\.rb$" | \
  xargs -I{} chef ai ask "What ChefSpec tests should be written for {}" > test_suggestions.md

# Exit with error code if issues found
if grep -q "Critical issue" issues.md; then
  echo "Critical issues found! See issues.md for details."
  exit 1
fi

echo "Chef AI analysis complete. All checks passed."
exit 0
```

## See Also

- [Integration Guide](integration_guide.md): Details on integrating with Chef tools
- [API Reference](api_reference.md): Full API documentation
- [Context Awareness](context_awareness.md): More about context awareness modes
