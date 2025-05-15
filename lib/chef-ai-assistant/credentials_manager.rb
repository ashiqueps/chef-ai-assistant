# frozen_string_literal: true

require 'json'
require 'fileutils'

module ChefAiAssistant
  class CredentialsManager
    class CredentialsNotFoundError < StandardError; end

    def self.credentials_file_path
      File.join(Dir.home, '.chef', 'ai_credentials')
    end

    def self.credentials_exist?
      File.exist?(credentials_file_path) && !File.zero?(credentials_file_path)
    end

    def self.load_credentials
      unless credentials_exist?
        raise CredentialsNotFoundError, "Credentials not found. Please run 'chef ai setup' to configure."
      end

      begin
        JSON.parse(File.read(credentials_file_path))
      rescue JSON::ParserError => e
        raise "Failed to parse credentials file: #{e.message}"
      end
    end

    def self.save_credentials(credentials)
      # Create directory if it doesn't exist
      FileUtils.mkdir_p(File.dirname(credentials_file_path))

      # Write credentials to file
      File.open(credentials_file_path, 'w') do |file|
        file.write(JSON.pretty_generate(credentials))
        # Set permissions to only allow current user to read/write
        file.chmod(0o600)
      end
    end
  end
end
