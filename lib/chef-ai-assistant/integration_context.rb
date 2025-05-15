# frozen_string_literal: true

module ChefAiAssistant
  # Class to track and manage the source of integration
  class IntegrationContext
    attr_accessor :parent_gem_name, :parent_gem_version, :parent_gem_description

    KNOWN_GEMS = {
      'chef' => 'Chef command-line tool for infrastructure automation',
      'chef-cli' => 'Chef Command Line Interface for workflow automation',
      'knife' => 'Chef knife tool for Chef Server interaction and node management',
      'test-kitchen' => 'Test Kitchen for automated testing of infrastructure code',
      'kitchen' => 'Test Kitchen for automated testing of infrastructure code',
      'inspec' => 'InSpec for compliance automation and security testing',
      'habitat' => 'Habitat for application packaging and runtime management',
      'hab' => 'Habitat for application packaging and runtime management',
      'chef-ecosystem' => 'Complete Chef ecosystem with all Chef tools and capabilities'
    }.freeze

    def initialize(parent_gem_name = nil, parent_gem_version = nil, parent_gem_description = nil)
      @parent_gem_name = parent_gem_name || 'chef'
      @parent_gem_version = parent_gem_version || 'unknown'
      @parent_gem_description = parent_gem_description || KNOWN_GEMS[@parent_gem_name.to_s] || 'Chef command-line tool'
    end

    # Returns a formatted string describing the integration context
    def to_s
      "#{@parent_gem_name} v#{@parent_gem_version}"
    end

    # Returns a detailed context for use in system prompts
    def context_for_prompt(strict_context = true)
      integration_info = "You are integrated with the #{@parent_gem_name} gem (v#{@parent_gem_version}), which is #{@parent_gem_description}."

      if strict_context
        integration_info += " Only answer questions and provide assistance related to the #{@parent_gem_name} functionality and usage."
      else
        integration_info += " You should focus on #{@parent_gem_name} but can also provide general Chef ecosystem assistance."
      end

      integration_info
    end

    # Define the scope of topics that this integration should handle
    def allowed_topics
      topics = {
        'chef' => ['chef', 'chef-cli', 'chef client', 'chef server', 'chefdk', 'chef workstation', 'chef generate',
                   'chef exec'],
        'chef-cli' => ['chef', 'chef-cli', 'chef client', 'chef server', 'chefdk', 'chef workstation', 'chef generate',
                       'chef exec'],
        'knife' => ['knife', 'chef server', 'nodes', 'data bags', 'environments', 'roles', 'cookbooks'],
        'test-kitchen' => ['test kitchen', 'kitchen', 'kitchen.yml', 'testing', 'infrastructure testing',
                           'kitchen driver'],
        'kitchen' => ['test kitchen', 'kitchen', 'kitchen.yml', 'testing', 'infrastructure testing', 'kitchen driver'],
        'inspec' => ['inspec', 'compliance', 'audit', 'security', 'controls', 'profiles', 'compliance automation'],
        'habitat' => ['habitat', 'hab', 'application packaging', 'runtime', 'supervisor', 'service', 'plans'],
        'hab' => ['habitat', 'hab', 'application packaging', 'runtime', 'supervisor', 'service', 'plans'],
        'chef-ecosystem' => ['chef', 'chef-cli', 'chef client', 'chef server', 'chefdk', 'chef workstation',
                             'knife', 'nodes', 'data bags', 'environments', 'roles', 'cookbooks',
                             'test kitchen', 'kitchen', 'kitchen.yml', 'testing',
                             'inspec', 'compliance', 'audit', 'security', 'controls', 'profiles',
                             'habitat', 'hab', 'application packaging', 'runtime', 'supervisor', 'service', 'plans']
      }

      topics[@parent_gem_name.to_s.downcase] || ['chef'] # Default to chef topics only
    end

    # Get a list of other related tools to suggest when outside scope
    def related_tools
      tools = %w[chef chef-cli knife inspec habitat test-kitchen]
      tools.reject { |t| t == @parent_gem_name.downcase }
    end

    # Returns a boundary enforcement message for the system prompt
    def boundary_message(strict_context = true)
      return '' unless strict_context

      related_tools_list = related_tools.join(', ')

      "IMPORTANT: You are currently integrated with #{@parent_gem_name}. " \
      "You must REFUSE to answer any questions about Chef tools that are not directly related to #{@parent_gem_name}. " \
      "For questions about other Chef ecosystem tools like #{related_tools_list}, " \
      "respond with: \"I'm currently integrated with #{@parent_gem_name} and can only assist with #{@parent_gem_name}-specific questions. " \
      'For questions about [REQUESTED_TOOL], please use the `[REQUESTED_TOOL] ai` command instead."'
    end

    # Detect the parent gem's purpose and return specialized instructions
    def specialized_instructions
      instructions = {
        'chef-cli' => 'Focus on chef command-line interface usage, workflow automation, and development aspects.',
        'knife' => 'Focus on infrastructure management, node interaction, data bag handling, and Chef Server communication.',
        'test-kitchen' => 'Focus on infrastructure testing, test configuration, drivers, verifiers, and test lifecycle management.',
        'kitchen' => 'Focus on infrastructure testing, test configuration, drivers, verifiers, and test lifecycle management.',
        'inspec' => 'Focus on compliance automation, security scanning, control writing, and compliance profile management.',
        'habitat' => 'Focus on application packaging, runtime supervision, service deployment, and application lifecycle.',
        'hab' => 'Focus on application packaging, runtime supervision, service deployment, and application lifecycle.',
        'chef-ecosystem' => 'Use the most appropriate Chef tool for each task. For node operations and Chef Server interaction, use knife commands. For local development, use chef commands. For compliance, use inspec. For application packaging, use habitat.'
      }

      instructions[@parent_gem_name.to_s.downcase] || 'Focus on general Chef ecosystem functionality and capabilities.'
    end

    # Get a specialized system prompt for the specific tool
    def specialized_system_prompt(base_prompt, command_type)
      # Check if strict context mode is enabled
      strict_context = ChefAiAssistant.configuration&.strict_context_aware.nil? || ChefAiAssistant.configuration.strict_context_aware

      # For relaxed context mode, add special instructions to override the boundary enforcement
      unless strict_context
        relaxed_boundary_override =
          'IMPORTANT OVERRIDE: Despite any other instructions in this prompt about strict integration context, ' \
          "you should answer questions about ANY Chef ecosystem tool, not just #{@parent_gem_name}. " \
          'You are free to provide information about InSpec, Knife, Chef Habitat, Chef Workstation, Test Kitchen, ' \
          "and all other Chef tools even though you are integrated with the #{@parent_gem_name} tool."
      end

      tool_contexts = if strict_context
                        {
                          'ask' => "Your task is to answer questions specifically related to #{@parent_gem_name} usage and capabilities.",
                          'command' => "Your task is to generate #{@parent_gem_name} commands from natural language descriptions.",
                          'explain' => "Your task is to explain #{@parent_gem_name}-related files, code, or concepts.",
                          'generate' => "Your task is to generate #{@parent_gem_name}-related files, code, or configuration.",
                          'migrate' => "Your task is to assist with #{@parent_gem_name} version migrations or upgrades.",
                          'troubleshoot' => "Your task is to troubleshoot #{@parent_gem_name}-related issues and errors."
                        }
                      else
                        {
                          'ask' => 'Your task is to answer questions about Chef and related technologies, including InSpec, Knife, Habitat, and all parts of the Chef ecosystem.',
                          'command' => "Your task is to generate Chef-related commands for any Chef tool, including #{@parent_gem_name}, InSpec, Knife, and others.",
                          'explain' => 'Your task is to explain Chef-related files, code, or concepts from any part of the Chef ecosystem.',
                          'generate' => 'Your task is to generate Chef-related files, code, or configuration for any Chef tool.',
                          'migrate' => 'Your task is to assist with Chef-related migrations or upgrades for any Chef tool.',
                          'troubleshoot' => 'Your task is to troubleshoot Chef-related issues and errors for any Chef tool.'
                        }
                      end

      command_key = command_type.to_s.downcase
      tool_context = tool_contexts[command_key] || "Your task is to provide assistance with #{strict_context ? @parent_gem_name : "the entire Chef ecosystem, including #{@parent_gem_name} and all related tools"}."

      version_info = @parent_gem_version != 'unknown' ? "You are using #{@parent_gem_name} version #{@parent_gem_version}." : ''

      components = [
        base_prompt,
        context_for_prompt(strict_context)
      ]

      # Add the relaxed boundary override first if in relaxed mode
      components << relaxed_boundary_override unless strict_context

      # Then continue with other components
      components += [
        boundary_message(strict_context),
        specialized_instructions,
        version_info,
        tool_context
      ]

      components.reject(&:empty?).join("\n\n")
    end
  end
end
