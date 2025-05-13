# frozen_string_literal: true

# This file contains enhanced extraction methods for the migration functionality
# to help properly extract full code blocks from AI responses

module ChefAiAssistant
  module Utils
    class MigrationUtils
      # Enhanced version of extract_updated_code for better pattern matching
      def self.extract_updated_code(analysis, original_content = nil, verbose = false)
        # Handle the case where our input is nil or empty
        return nil if analysis.nil? || analysis.empty?
        return original_content if original_content && (analysis.nil? || analysis.empty?)

        # First try to extract code from Ruby code blocks (most precise)
        # Non-greedy pattern matching to get full content between triple backticks
        if analysis =~ /```ruby\s*\n(.*?)\n```/m
          extracted_code = ::Regexp.last_match(1)
          # Verify the extracted code is complete by ensuring it has the same overall structure
          if original_content && extracted_code
            # Count module/class/def blocks to verify completeness
            orig_module_count = original_content.scan(/^\s*module\s+/).count
            orig_class_count = original_content.scan(/^\s*class\s+/).count
            orig_end_count = original_content.scan(/^\s*end/).count

            ext_module_count = extracted_code.scan(/^\s*module\s+/).count
            ext_class_count = extracted_code.scan(/^\s*class\s+/).count
            ext_end_count = extracted_code.scan(/^\s*end/).count

            if (orig_module_count.positive? && ext_module_count.zero?) ||
               (orig_class_count.positive? && ext_class_count.zero?) ||
               (orig_end_count.positive? && ext_end_count.zero?)
              # Structure doesn't match, might be incomplete
              puts 'DEBUG: Code structure mismatch. Using original content.' if verbose
            else
              # Structure seems to match or no major structure in original
              return extracted_code unless extracted_code.empty?
            end
          elsif extracted_code && !extracted_code.empty?
            # If we don't have original content for comparison or extracted is empty
            return extracted_code
          end
        end

        # Try to find any code block if ruby-specific wasn't found or was incomplete
        if analysis =~ /```(?:ruby)?\s*\n(.*?)\n```/m
          extracted_code = ::Regexp.last_match(1)
          if extracted_code && !extracted_code.empty?
            # Basic validation - if it has ruby syntax elements, it's probably good
            return extracted_code
          end
        end

        # Look for all code blocks in the analysis and concatenate them if multiple blocks that seem to be parts of the same file
        all_code_blocks = analysis.scan(/```(?:ruby)?\s*\n(.*?)\n```/m).flatten
        if all_code_blocks.size > 1
          # Check if blocks seem to be parts of the same file (common in longer files)
          combined_code = all_code_blocks.join("\n\n")
          return combined_code if combined_code.include?('module') && combined_code.include?('end')
        elsif all_code_blocks.size == 1 && !all_code_blocks[0].empty?
          return all_code_blocks[0]
        end

        # Look for sections explicitly marked as updated code
        return ::Regexp.last_match(1) if analysis =~ /UPDATED CODE:\s*\n(.*?)(\n\n|\z)/m

        # Look for content between headers and the next section
        [
          /Updated Code for Chef \d+.*?```(?:ruby)?\s*\n(.*?)\n```/mi,
          /MIGRATED CODE:.*?```(?:ruby)?\s*\n(.*?)\n```/mi,
          /UPDATED FILE:.*?```(?:ruby)?\s*\n(.*?)\n```/mi,
          /Compatible Code:.*?```(?:ruby)?\s*\n(.*?)\n```/mi,
          /Here is the migrated code:.*?```(?:ruby)?\s*\n(.*?)\n```/mi
        ].each do |pattern|
          if analysis =~ pattern
            extracted_code = ::Regexp.last_match(1)
            return extracted_code if extracted_code && !extracted_code.empty?
          end
        end

        # Try to find any remaining code blocks with a more aggressive pattern
        if analysis =~ /```.*?\n(.*?)```/m
          extracted_code = ::Regexp.last_match(1)
          return extracted_code unless extracted_code.empty?
        end

        # If all extraction methods failed but we have a code block without proper markdown formatting
        raw_code_pattern = /def.*?end|module.*?end|class.*?end/m
        if analysis =~ raw_code_pattern && original_content
          # Extract the largest matching block
          largest_block = analysis.scan(raw_code_pattern).max_by(&:length)
          if largest_block && largest_block.length > 100 # Arbitrary threshold to avoid false positives
            return largest_block
          end
        end

        # Handle special cases - extract everything after a heading that indicates code follows
        [
          /### Updated Code .*?\n\n(.*)/mi,
          /## Migrated Code.*?\n\n(.*)/mi
        ].each do |pattern|
          return ::Regexp.last_match(1) if analysis =~ pattern
        end

        # Look for specific code changes that need to be made
        if original_content && analysis.include?('ISSUE:')
          # Extract all instances where exit is mentioned to be changed to exit!
          if analysis =~ /exit[^!]/i && analysis =~ /exit!/i
            modified_content = original_content.gsub(/\bexit\s+(\d+)/) { "exit! #{::Regexp.last_match(1)}" }
            return modified_content if modified_content != original_content
          end

          # Look for other specific changes mentioned in the analysis
          if analysis =~ /Replace\s+`([^`]+)`\s+with\s+`([^`]+)`/i
            from = ::Regexp.last_match(1)
            to = ::Regexp.last_match(2)
            modified_content = original_content.gsub(from, to)
            return modified_content if modified_content != original_content
          end
        end

        # If no issues were found, return the original file content
        if !analysis.include?('ISSUE:') && !analysis.include?('WARNING:') && !analysis.include?('DEPRECATED:') && original_content
          return original_content
        end

        # If we couldn't extract code but the AI declared no issues, return original code
        if analysis =~ /(?:no issues found|no migration needed|no changes required|file is compatible|all files appear compatible)/i && original_content
          return original_content
        end

        # Get any potential extracted code from the analysis so far
        extracted_code = nil
        analysis.scan(/```(?:ruby)?\s*\n(.*?)\n```/m).flatten.each do |block|
          extracted_code = block if block && !block.empty? && (!extracted_code || block.length > extracted_code.length)
        end

        # Safety check - if original_content is available and we have issues with extraction
        if original_content && (!extracted_code || extracted_code.length < original_content.length * 0.5)
          # If content extraction is much smaller than original, return original
          if verbose
            puts "Code extraction incomplete (#{extracted_code&.length || 0} vs #{original_content.length} bytes), using original content."
          end
          return original_content
        end

        # Special case for code extraction failures: if we've tried all extraction methods
        # and only have a small portion of the code, but we have the original content
        # return the original content with any specific mentions of changes applied
        if original_content && (
           # If extracted code would be under 30% of original, it's probably incomplete
           (extracted_code && extracted_code.length < original_content.length * 0.3) ||
           # If we didn't get any extracted code at all
           extracted_code.nil?
         )
          # Look for specific code changes before returning original
          modified_content = original_content.dup

          # Apply any specific replacements mentioned in the analysis
          analysis.scan(/replace\s+['"`]([^'"`]+)['"`]\s+with\s+['"`]([^'"`]+)['"`]/i) do |from, to|
            modified_content.gsub!(from, to) if from && to
          end

          return modified_content
        end

        # If we have original content, but couldn't extract proper changes, return the original as a fallback
        return original_content if original_content

        nil
      end
    end
  end
end
