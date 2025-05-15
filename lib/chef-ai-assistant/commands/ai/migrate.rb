# frozen_string_literal: true

require 'optparse'
require 'tty-spinner'
require 'tty-prompt'
require 'rainbow'
require 'fileutils'
require 'json'
require 'date'
require_relative '../../utils/migration_utils'

module ChefAiAssistant
  module Commands
    class Ai
      class Migrator < ChefAiAssistant::Command::Base
        # Major Chef version changes to help guide migrations
        MAJOR_CHEF_CHANGES = {
          '11' => {
            released: 'February 2013',
            eol: 'February 2016',
            highlights: [
              'Full Erchef (Erlang-based Chef server)',
              'Enterprise Chef introduced',
              'Environments feature enhancement'
            ]
          },
          '12' => {
            released: 'November 2014',
            eol: 'April 2018',
            highlights: [
              'Chef client -z (local mode)',
              'Custom resources simplified',
              'Policyfiles introduced',
              'Chef provisioning'
            ]
          },
          '13' => {
            released: 'April 2017',
            eol: 'April 2019',
            highlights: [
              'Habitat integration',
              'Windows DSC integration',
              'Cookbook hoisting via Berkshelf',
              'Resource action notification changes'
            ]
          },
          '14' => {
            released: 'February 2018',
            eol: 'April 2020',
            highlights: [
              'Chef Automate 2.0 integration',
              'Custom resource enhancements',
              'Notification changes',
              'New package and resource options'
            ]
          },
          '15' => {
            released: 'May 2019',
            eol: 'April 2021',
            highlights: [
              'Chef Workstation replaces ChefDK',
              'Chef InSpec integration',
              'Target mode introduction',
              'Multiple new resources'
            ]
          },
          '16' => {
            released: 'April 2020',
            eol: 'April 2022',
            highlights: [
              'Unified Chef Infra Client',
              'Improved resource subsystem',
              'Many resources moved to core',
              'Deprecation of legacy resources'
            ]
          },
          '17' => {
            released: 'March 2021',
            eol: 'April 2023',
            highlights: [
              'Ruby 3.0 support',
              'New unified mode default for resources',
              'Resource guard improvements',
              'Compliance phase improvements'
            ]
          },
          '18' => {
            released: 'April 2022',
            eol: 'April 2024',
            highlights: [
              'Ruby 3.1 support',
              'Secret management improvements',
              'New file system and platform resources',
              'Performance improvements'
            ]
          }
        }.freeze

        def setup_command
          @name = 'migrate'
          @description = 'Assist with migrations between Chef versions'
          @banner = 'Usage: chef ai migrate [options] [PATH]'
          @options = {
            '--help, -h' => 'Show this message',
            '--from VERSION' => 'Source Chef version (e.g., 14)',
            '--to VERSION' => 'Target Chef version (e.g., 17)',
            '--output PATH, -o PATH' => 'Specify output directory for migrated files (default: creates backup of originals)',
            '--scan-only' => 'Only scan for compatibility issues without making changes',
            '--temperature TEMP' => 'Set the response creativity (0.0-2.0)',
            '--verbose, -v' => 'Show detailed response information'
          }
          @verbose = false
          @temperature = 0.3 # Lower temperature for more deterministic migrations
          @scan_only = false
          @source_version = nil
          @target_version = nil
          @output_dir = nil
          @path = Dir.pwd # Default to current directory

          # Load the system prompt using the template renderer
          load_system_prompt(nil, 'migrate')
        end

        def run(args = [])
          if args.empty? || args.include?('--help') || args.include?('-h')
            help
            return 0
          end

          # Parse options
          remaining_args = parse_options(args)

          # The remaining arg is the path to analyze
          @path = File.expand_path(remaining_args.first) if remaining_args.any?

          # Validate required options
          prompt = TTY::Prompt.new
          @source_version = prompt.ask('Please specify the source Chef version:', default: '14') if @source_version.nil?

          @target_version = prompt.ask('Please specify the target Chef version:', default: '17') if @target_version.nil?

          # Show major changes between versions
          show_version_changes(prompt, @source_version, @target_version)

          # Validate path
          unless File.exist?(@path)
            prompt.error("The specified path does not exist: #{@path}")
            return 1
          end

          # Confirm before proceeding
          if prompt.yes?("\n#{Rainbow('Do you want to proceed with the migration analysis?').bright.yellow}")
            # Process the migration
            process_migration
          else
            prompt.warn('Migration cancelled by user')
            return 0
          end
          0
        end

        def parse_options(args)
          parser = OptionParser.new do |opts|
            opts.banner = @banner

            opts.on('-h', '--help', 'Show this message') do
              help
              exit 0
            end

            opts.on('--from VERSION', 'Source Chef version (e.g., 14)') do |version|
              @source_version = version
            end

            opts.on('--to VERSION', 'Target Chef version (e.g., 17)') do |version|
              @target_version = version
            end

            opts.on('-o', '--output PATH', 'Specify output directory for migrated files') do |path|
              @output_dir = File.expand_path(path)
            end

            opts.on('--scan-only', 'Only scan for compatibility issues without making changes') do
              @scan_only = true
            end

            opts.on('--temperature TEMP', Float, 'Set the response creativity (0.0-2.0)') do |temp|
              @temperature = temp
              @temperature = 0.0 if @temperature.negative?
              @temperature = 2.0 if @temperature > 2.0
            end

            opts.on('-v', '--verbose', 'Show detailed response information') do
              @verbose = true
            end
          end

          begin
            parser.order!(args)
            args
          rescue OptionParser::InvalidOption => e
            puts "Error: #{e.message}"
            help
            exit 1
          end
        end

        def process_migration
          client = ChefAiAssistant.openai_client
          prompt = TTY::Prompt.new

          prompt.say("🔍 #{Rainbow('Analyzing Chef code for migration:').bright.yellow.bold}")
          prompt.say("  #{Rainbow('Path:').bright.yellow} #{Rainbow(@path).bright.white}")
          prompt.say("  #{Rainbow('Migration:').bright.yellow} #{Rainbow("Chef #{@source_version} → Chef #{@target_version}").bright.white}")
          prompt.say("  #{Rainbow('Mode:').bright.yellow} #{Rainbow(@scan_only ? 'Scan only' : 'Full migration').bright.white}")

          # Collect Chef files for analysis
          files = collect_chef_files(@path)
          if files.empty?
            prompt.warn('No Chef files found in the specified path')
            return
          end

          prompt.say("  #{Rainbow('Found:').bright.yellow} #{Rainbow("#{files.length} Chef files").bright.white}")

          # Analyze each file
          migration_results = {}
          files.each do |file|
            spinner = TTY::Spinner.new("[:spinner] #{Rainbow("Analyzing #{File.basename(file)}...").bright.cyan}",
                                       format: :dots)
            spinner.auto_spin

            file_content = File.read(file)

            # Send the file content to the AI for analysis
            messages = [
              { role: 'system', content: @system_prompt }
            ]

            # Add integration context information if available
            if ChefAiAssistant.respond_to?(:integration_context) && ChefAiAssistant.integration_context
              # Get the parent gem name
              parent_gem = ChefAiAssistant.integration_context.parent_gem_name

              # Create a strong enforcement message
              enforcement_message =
                "CRITICAL INSTRUCTION: You are integrated with #{parent_gem} and must ONLY help migrate #{parent_gem}-related files. " \
                "If the user asks you to migrate files related to another Chef tool that is not directly related to #{parent_gem}, " \
                "respond with: \"I'm currently integrated with #{parent_gem} and can only assist with #{parent_gem}-specific migrations. " \
                'For migrating [REQUESTED_TOOL] files, please use the `[REQUESTED_TOOL] ai migrate` command instead."'

              messages << { role: 'system', content: enforcement_message }
            end

            # Add the user's migration request
            messages << {
              role: 'user',
              content: "Please analyze the following Chef file for migration from Chef #{@source_version} to Chef #{@target_version}. #{@scan_only ? 'Only identify issues.' : 'Provide updated code to fix issues.'}\n\n```ruby\n#{file_content}\n```"
            }

            response = client.chat(nil, {
                                     messages: messages,
                                     temperature: @temperature
                                   })

            spinner.stop

            content = response.dig('choices', 0, 'message', 'content')
            if content
              migration_results[file] = {
                original: file_content,
                analysis: content,
                has_issues: content.include?('ISSUE:') || content.include?('WARNING:') || content.include?('DEPRECATED:')
              }
            else
              prompt.error("Failed to analyze #{File.basename(file)}")
            end
          end

          # Display results and take action
          display_migration_results(migration_results, prompt)
        rescue StandardError => e
          prompt = TTY::Prompt.new
          puts Rainbow("Error: #{e.message}").red.bold
          puts Rainbow(e.backtrace.join("\n")).red if @verbose
        end

        def show_version_changes(prompt, source_version, target_version)
          prompt.say("\n#{Rainbow('Chef Version Migration Overview:').bright.blue.bold}")

          # Clean version numbers
          source = source_version.to_s.split('.').first
          target = target_version.to_s.split('.').first

          # Skip if versions aren't in our data
          unless MAJOR_CHEF_CHANGES.key?(source) && MAJOR_CHEF_CHANGES.key?(target)
            prompt.warn("Detailed version information not available for Chef #{source} to Chef #{target} migration")
            return
          end

          # Show source version info
          prompt.say("\n#{Rainbow('Source:').bright.yellow} #{Rainbow("Chef #{source}").bright.white} " \
            "(Released: #{MAJOR_CHEF_CHANGES[source][:released]}, EOL: #{MAJOR_CHEF_CHANGES[source][:eol]})")

          # Show target version info
          prompt.say("#{Rainbow('Target:').bright.yellow} #{Rainbow("Chef #{target}").bright.white} " \
            "(Released: #{MAJOR_CHEF_CHANGES[target][:released]}, EOL: #{MAJOR_CHEF_CHANGES[target][:eol]})")

          # If it's only one version difference, show direct changes
          if target.to_i - source.to_i == 1
            prompt.say("\n#{Rainbow("Major changes in Chef #{target}:").bright.yellow}")
          else
            # Show intermediate versions when skipping multiple versions
            prompt.say("\n#{Rainbow('Versions being skipped:').bright.yellow}")

            ((source.to_i + 1)...target.to_i).each do |v|
              v_str = v.to_s
              next unless MAJOR_CHEF_CHANGES.key?(v_str)

              prompt.say("  #{Rainbow("Chef #{v_str}").bright.white} (#{MAJOR_CHEF_CHANGES[v_str][:released]})")
              MAJOR_CHEF_CHANGES[v_str][:highlights].each do |change|
                prompt.say("    #{Rainbow('•').yellow} #{change}")
              end
              puts
            end

            # Show target version highlights
            prompt.say(Rainbow("New in Chef #{target}:").bright.yellow.to_s)
          end
          MAJOR_CHEF_CHANGES[target][:highlights].each do |change|
            prompt.say("  #{Rainbow('•').yellow} #{change}")
          end

          # Warning if source version is EOL
          source_date = begin
            Date.parse(MAJOR_CHEF_CHANGES[source][:eol])
          rescue StandardError
            nil
          end
          if source_date && source_date < Date.today
            prompt.say("\n#{Rainbow('⚠️').red} #{Rainbow("Chef #{source} reached end-of-life on #{MAJOR_CHEF_CHANGES[source][:eol]}").red}")
            prompt.say("  #{Rainbow('This version no longer receives updates or security fixes.').red}")
          end

          # Warning if target version is EOL or approaching EOL
          target_date = begin
            Date.parse(MAJOR_CHEF_CHANGES[target][:eol])
          rescue StandardError
            nil
          end
          return unless target_date

          if target_date < Date.today
            prompt.say("\n#{Rainbow('⚠️').red} #{Rainbow("Chef #{target} reached end-of-life on #{MAJOR_CHEF_CHANGES[target][:eol]}").red}")
            prompt.say("  #{Rainbow('Consider migrating to a newer supported version instead.').red}")
          elsif (target_date - Date.today).to_i < 180 # Less than 6 months to EOL
            prompt.say("\n#{Rainbow('⚠').yellow} #{Rainbow("Chef #{target} will reach end-of-life on #{MAJOR_CHEF_CHANGES[target][:eol]}").yellow}")
            prompt.say("  #{Rainbow('Consider planning for another migration in the future.').yellow}")
          end
        end

        private

        def collect_chef_files(path)
          files = []

          if File.directory?(path)
            # Common Chef file patterns
            patterns = [
              '**/*.rb',                    # All Ruby files
              '**/metadata.rb',             # Cookbook metadata
              '**/recipes/**/*.rb',         # Recipe files
              '**/attributes/**/*.rb',      # Attribute files
              '**/resources/**/*.rb',       # Resource files
              '**/providers/**/*.rb',       # Provider files
              '**/libraries/**/*.rb',       # Library files
              '**/definitions/**/*.rb',     # Definition files
              '**/Policyfile.rb',           # Policyfiles
              '**/Berksfile',               # Berksfiles
              '**/Cheffile',                # Cheffiles
              '**/knife.rb',                # Knife config
              '**/client.rb',               # Chef client config
              '**/solo.rb'                  # Chef solo config
            ]

            # Collect files matching patterns
            patterns.each do |pattern|
              Dir.glob(File.join(path, pattern)).each do |file|
                files << file if File.file?(file)
              end
            end
          elsif File.file?(path) && path.end_with?('.rb', 'Berksfile', 'Cheffile')
            files << path
          end

          files.uniq
        end

        def display_migration_results(results, prompt)
          prompt.say("\n#{Rainbow('Migration Analysis Results:').bright.blue.bold}")

          if results.empty?
            prompt.say(Rainbow('No files were analyzed').yellow.to_s)
            return
          end

          # Categorize files
          files_with_issues = results.select { |_, data| data[:has_issues] }.keys
          files_without_issues = results.keys - files_with_issues

          # Summary
          prompt.say("#{Rainbow('Files analyzed:').bright.yellow} #{results.size}")
          prompt.say("#{Rainbow('Files with issues:').bright.yellow} #{files_with_issues.size}")
          prompt.say("#{Rainbow('Files without issues:').bright.yellow} #{files_without_issues.size}")

          if files_with_issues.empty?
            prompt.say("\n#{Rainbow('✓').green} #{Rainbow("All files appear compatible with Chef #{@target_version}").green.bold}")
            return
          end

          # Process files with issues
          prompt.say("\n#{Rainbow('Files requiring migration:').bright.yellow.bold}")

          files_with_issues.each do |file|
            relative_path = file.sub("#{Dir.pwd}/", '')
            prompt.say("  #{Rainbow('•').yellow} #{Rainbow(relative_path).bright.white}")
          end

          return if @scan_only

          # Perform migrations if not in scan-only mode
          if prompt.yes?("\n#{Rainbow('Would you like to perform the migration?').bright.yellow}")
            perform_migration(results, files_with_issues, prompt)
          else
            prompt.say("\n#{Rainbow('Migration cancelled').yellow}")

            # Offer to show detailed analysis
            if prompt.yes?(Rainbow('Would you like to see the detailed analysis?').bright.yellow.to_s)
              display_detailed_analysis(results, prompt)
            end
          end
        end

        def perform_migration(results, files_with_issues, prompt)
          # Create output directory if specified
          output_dir = @output_dir
          create_backups = output_dir.nil?

          if create_backups
            # Use backup directory in the same location as the input
            backup_dir = if File.directory?(@path)
                           File.join(@path, "chef_migration_backup_#{Time.now.strftime('%Y%m%d%H%M%S')}")
                         else
                           File.join(File.dirname(@path), "chef_migration_backup_#{Time.now.strftime('%Y%m%d%H%M%S')}")
                         end
            FileUtils.mkdir_p(backup_dir)
            prompt.say("\n#{Rainbow('Creating backups in:').bright.yellow} #{Rainbow(backup_dir).bright.white}")
          else
            FileUtils.mkdir_p(output_dir)
            prompt.say("\n#{Rainbow('Generating migrated files in:').bright.yellow} #{Rainbow(output_dir).bright.white}")
          end

          # Process each file
          success_count = 0

          files_with_issues.each do |file|
            # Extract updated content from analysis
            analysis = results[file][:analysis]
            original_content = results[file][:original]
            # Use the enhanced extraction method for better pattern matching
            updated_content = ChefAiAssistant::Utils::MigrationUtils.extract_updated_code(analysis, original_content,
                                                                                          @verbose)

            if updated_content.nil?
              prompt.error("Failed to extract updated code for #{File.basename(file)}")

              # Offer to save the analysis text
              if prompt.yes?("Would you like to see the analysis for #{File.basename(file)}?")
                puts
                puts analysis

                # Offer to save analysis to a file
                if prompt.yes?("\nWould you like to save this analysis to a file?")
                  analysis_file = "#{File.basename(file, '.*')}_migration_analysis.txt"
                  output_path = create_backups ? backup_dir : output_dir
                  analysis_path = File.join(output_path, analysis_file)

                  begin
                    File.write(analysis_path, analysis)
                    prompt.say("  #{Rainbow('✓').green} Saved analysis to #{Rainbow(analysis_path).bright.white}")
                  rescue StandardError => e
                    prompt.error("Failed to write analysis: #{e.message}")
                  end
                end
              end

              next
            end

            # Determine target path
            if create_backups
              # Create backup of original
              backup_path = File.join(backup_dir, File.basename(file))
              FileUtils.cp(file, backup_path)
              target_path = file
            elsif File.directory?(@path)
              # Create in output directory, preserving relative path if input is directory
              rel_path = file.sub(%r{^#{Regexp.escape(@path)}/}, '')
              target_path = File.join(output_dir, rel_path)
              FileUtils.mkdir_p(File.dirname(target_path))
            else
              target_path = File.join(output_dir, File.basename(file))
            end

            # Debug and validation check
            if @verbose
              prompt.say("  #{Rainbow('Debug:').yellow} Content length: #{updated_content.length} bytes")
              prompt.say("  #{Rainbow('Debug:').yellow} Content starts with: #{updated_content[0..50]}...")
              prompt.say("  #{Rainbow('Debug:').yellow} Content ends with: #{updated_content[-50..-1]}...")
              prompt.say("  #{Rainbow('Debug:').yellow} Original length: #{original_content.length} bytes")
              prompt.say("  #{Rainbow('Debug:').yellow} Analysis contains 'ISSUE:': #{analysis.include?('ISSUE:')}")
              prompt.say("  #{Rainbow('Debug:').yellow} Analysis contains 'WARNING:': #{analysis.include?('WARNING:')}")
              prompt.say("  #{Rainbow('Debug:').yellow} Analysis contains 'DEPRECATED:': #{analysis.include?('DEPRECATED:')}")
              prompt.say("  #{Rainbow('Debug:').yellow} Analysis contains 'compatible': #{analysis =~ /compatible/i ? 'Yes' : 'No'}")
            end

            # Write the updated file - but only if its size is reasonable
            begin
              # Safety check to ensure we're not writing truncated content
              original_length = original_content.length
              updated_length = updated_content.length

              if updated_length < original_length * 0.8 && original_length > 500
                # Content is suspiciously shorter than original
                prompt.warn("Generated content (#{updated_length} bytes) is significantly shorter than original (#{original_length} bytes)")
                if prompt.yes?('Would you like to use the original file instead?')
                  updated_content = original_content
                  prompt.say("  #{Rainbow('!').yellow} Using original content for #{Rainbow(File.basename(file)).bright.white}")
                end
              end

              File.write(target_path, updated_content)
              success_count += 1
              prompt.say("  #{Rainbow('✓').green} Migrated #{Rainbow(File.basename(file)).bright.white} (#{updated_content.length} bytes)")
            rescue StandardError => e
              prompt.error("Failed to write #{File.basename(file)}: #{e.message}")
            end
          end

          # Summary
          prompt.say("\n#{Rainbow('Migration Summary:').bright.blue.bold}")
          prompt.say(Rainbow("#{success_count} of #{files_with_issues.size} files migrated successfully").green.to_s)

          if create_backups
            prompt.say("#{Rainbow('Original files backed up in:').bright.yellow} #{Rainbow(backup_dir).bright.white}")
          else
            prompt.say("#{Rainbow('Migrated files available in:').bright.yellow} #{Rainbow(output_dir).bright.white}")
          end
        end

        # The extract_updated_code method has been moved to migrate_enhancement.rb
        # This removes duplication and improves maintainability

        def display_detailed_analysis(results, prompt)
          files_with_issues = results.select { |_, data| data[:has_issues] }.keys

          files_with_issues.each do |file|
            prompt.say("\n#{Rainbow('Analysis for:').bright.blue.bold} #{Rainbow(file).bright.white}")

            # Format and display the analysis
            analysis = results[file][:analysis]
            colored_analysis = analysis.gsub(/ISSUE:|WARNING:|DEPRECATED:/) do |match|
              Rainbow(match).red.bold
            end

            puts colored_analysis

            # Pause between files if there are multiple
            prompt.keypress("\nPress any key to see the next file analysis...") if file != files_with_issues.last
          end
        end
      end
    end
  end
end
