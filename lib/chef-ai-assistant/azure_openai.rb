# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

module ChefAiAssistant
  class AzureOpenAI
    attr_reader :config

    def initialize(config = {})
      @config = {
        api_key: ENV['AZURE_OPENAI_API_KEY'],
        api_version: ENV['AZURE_OPENAI_API_VERSION'] || '2023-05-15',
        azure_endpoint: ENV['AZURE_OPENAI_ENDPOINT'],
        deployment_name: ENV['AZURE_OPENAI_DEPLOYMENT_NAME']
      }.merge(config)

      validate_config
    end

    def chat(prompt, options = {})
      # If prompt is nil, assume options contains messages already
      default_options = if prompt.nil? && options[:messages]
                          {
                            temperature: 0.7,
                            max_tokens: 800
                          }
                        else
                          {
                            messages: [{ role: 'user', content: prompt.to_s }],
                            temperature: 0.7,
                            max_tokens: 800
                          }
                        end

      options = default_options.merge(options)

      # Azure OpenAI doesn't use the model parameter in the same way
      options.delete(:model) if options[:model]

      # Make the API call with the specified deployment
      response = make_api_call('chat/completions', @config[:deployment_name], options)

      # Check for errors in the response
      if response.is_a?(Hash) && response['error']
        error_msg = response['error']['message'] || 'Unknown error'
        error_code = response['error']['code'] || 'unknown'

        puts "Azure OpenAI API Error (#{error_code}): #{error_msg}"
        puts 'Debug info:'
        puts "  Endpoint: #{@config[:azure_endpoint]}"
        puts "  Deployment: #{@config[:deployment_name]}"
        puts "  API Version: #{@config[:api_version]}"
      end

      response
    end

    private

    def validate_config
      required_keys = %i[api_key api_version azure_endpoint]
      missing_keys = required_keys.select { |key| @config[key].nil? || @config[key].empty? }

      raise ConfigurationError, "Missing required configuration: #{missing_keys.join(', ')}" if missing_keys.any?

      # Set a default deployment name if not provided
      if @config[:deployment_name].nil? || @config[:deployment_name].empty?
        puts "WARNING: No deployment_name specified. Using 'gpt-35-turbo' as default model."
        puts "This may not work if you haven't created this deployment in your Azure OpenAI resource."
        @config[:deployment_name] = 'gpt-35-turbo'
      end

      # Ensure the endpoint doesn't have a trailing slash
      @config[:azure_endpoint] = @config[:azure_endpoint].chomp('/')
    end

    # General method to make API calls to Azure OpenAI
    def make_api_call(endpoint, deployment_name = nil, body = nil, method = :post)
      # Build the URI based on whether we're accessing a deployment-specific endpoint
      uri = if deployment_name
              URI.parse("#{@config[:azure_endpoint]}/openai/deployments/#{deployment_name}/#{endpoint}?api-version=#{@config[:api_version]}")
            else
              URI.parse("#{@config[:azure_endpoint]}/openai/#{endpoint}?api-version=#{@config[:api_version]}")
            end

      # Create HTTP client with proper timeouts
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.read_timeout = 60
      http.open_timeout = 30

      # Create request based on method
      request = case method
                when :get
                  Net::HTTP::Get.new(uri.request_uri)
                when :post
                  Net::HTTP::Post.new(uri.request_uri)
                when :put
                  Net::HTTP::Put.new(uri.request_uri)
                when :delete
                  Net::HTTP::Delete.new(uri.request_uri)
                end

      # Set common headers
      request['api-key'] = @config[:api_key]

      # Set content type and body for POST and PUT requests
      if %i[post put].include?(method) && body
        request['Content-Type'] = 'application/json'
        request.body = body.to_json
      end

      response = http.request(request)

      # Handle response
      if response.code.to_i >= 200 && response.code.to_i < 300
        # Success response - parse JSON if body exists
        if response.body && !response.body.empty?
          begin
            JSON.parse(response.body)
          rescue JSON::ParserError
            { 'error' => { 'message' => 'Invalid JSON in response body', 'code' => 'json_error' } }
          end
        else
          # No body in response
          { 'result' => 'success' }
        end
      else
        # Error response - try to parse error details if available
        begin
          if response.body && !response.body.empty?
            JSON.parse(response.body)

          else
            { 'error' => { 'message' => "HTTP #{response.code}: #{response.message}", 'code' => response.code } }
          end
        rescue JSON::ParserError
          { 'error' => { 'message' => "HTTP #{response.code}: #{response.message}", 'code' => response.code } }
        end
      end
    rescue StandardError => e
      { 'error' => { 'message' => e.message, 'code' => 'request_error' } }
    end
  end

  class ConfigurationError < StandardError; end
end
