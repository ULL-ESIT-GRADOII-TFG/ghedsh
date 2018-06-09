require 'version'
require 'common'
require 'ostruct'
require 'fileutils'

# Class that registers commands into has COMMANDS located in common.rb
# The interface access that hash to look up for the command. If command is defined,
# and the class that points @deep has the method defined, the interface calls it with
# parameters provided.
#
# If a command should be available in different contexts, each class (e.g User or Organization)
# must implement that command (and perform acrions related to that context)
class Commands
  attr_reader :enviroment

  # when Commands class is instantiated, all methods are added to COMMANDS hash with a name (string)
  # that identify each one and the caller method within Commands class.
  def initialize
    @context_stack = []
    add_command('clear', method(:clear))
    # add_command('help', method(:help))
    add_command('exit', method(:exit))
    add_command('new_issue', method(:new_issue))
    add_command('issues', method(:display_issues))
    add_command('repos', method(:display_repos))
    add_command('new_repo', method(:new_repo))
    add_command('rm_repo', method(:rm_repo))
    add_command('new_team', method(:new_team))
    add_command('set_private', method(:set_private))
    add_command('set_public', method(:set_public))
    add_command('files', method(:show_files))
    add_command('rm_team', method(:rm_team))
    add_command('clone', method(:clone_repo))
    add_command('rm_cloned', method(:delete_cloned_repos))
    add_command('commits', method(:display_commits))
    add_command('orgs', method(:display_orgs))
    add_command('new_eval', method(:new_eval))
    add_command('foreach_eval', method(:foreach_eval))
    add_command('invite_member', method(:invite_member))
    add_command('remove_member', method(:remove_member))
    add_command('invite_member_from_file', method(:invite_member_from_file))
    add_command('invite_outside_collaborators', method(:invite_outside_collaborators))
    add_command('people', method(:display_people))
    add_command('teams', method(:display_teams))
    add_command('orgsn', method(:orgsn))
    add_command('cd', method(:change_context))
    add_command('open', method(:open))
    add_command('bash', method(:bash))
  end

  # Fills COMMANDS hash with available commands.
  #
  # @param [String] command_name string that identifies a command, when user types it, command
  #  executes depending on context.
  # @param [Method] command method inside Class Commands that triggers the action depending on where
  #  is pointing @deep
  def add_command(command_name, command)
    COMMANDS[command_name] = command
  end

  # Gets enviroment from class ShellContext. Includes all GitHub authenticated user configuration,
  # ghedsh configuration etc.
  # Also it stores the default enviroment to avoid context_stack underflow.
  #
  # @param [ShellContext] console_enviroment object containing running enviroment.
  def load_enviroment(console_enviroment)
    @enviroment = console_enviroment
    @default_enviroment = OpenStruct.new
    default_config = {
      'User' => @enviroment.client.login.to_s,
      'user_url' => @enviroment.client.web_endpoint.to_s << @enviroment.client.login.to_s,
      'Org' => nil,
      'org_url' => nil,
      'Repo' => nil,
      'repo_url' => nil,
      'Team' => nil,
      'team_url' => nil,
      'TeamID' => nil,
      'Assig' => nil
    }
    @default_enviroment.config = default_config
    @default_enviroment.deep = User
    @context_stack.push(@default_enviroment)
  end

  # Display organization depending on context. If method is not defined in current deep, information
  # is provided.
  #
  # @param [Array<String>] params user provided parameters, like Regexp to show matching organizations
  def display_orgs(params)
    if @enviroment.deep.method_defined? :show_organizations
      @enviroment.deep.new.show_organizations(@enviroment.client, params)
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  # Creates a 'super repo' containing subrepos of assignments
  #
  # @param [Array<String>] params first provide name of eval repository and a Regexp to match
  # repos to add them as submodules
  def new_eval(params)
    if @enviroment.deep.method_defined? :new_eval
      @enviroment.deep.new.new_eval(@enviroment.client, @enviroment.config, params)
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  # Run a bash command over each submodule inside a evaluation repo
  # Requirements: Current working directory must be the evaluation repo containing all submodules
  #
  # @param [Array<String>] params command to run over each submodule
  def foreach_eval(params)
    if @enviroment.deep.method_defined? :foreach_eval
      @enviroment.deep.new.foreach_eval(@enviroment.client, @enviroment.config, params)
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  # Display files from current repo.
  #
  # @param [Array<String>] params user provided parameters, like path within a repository
  def show_files(params)
    if @enviroment.deep.method_defined? :show_files
      @enviroment.deep.new.show_files(@enviroment.client, @enviroment.config, params)
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  # Invite member to organization
  # @param [Array<String>] params user provided parameters, like members to be added
  def invite_member(params)
    if @enviroment.deep.method_defined? :add_members
      @enviroment.deep.new.add_members(@enviroment.client, @enviroment.config, params)
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  # Invite members from JSON files. file_templates directory has template with file structure for this command.
  # @param [Array<String>] params path to JSON file  containing members
  def invite_member_from_file(params)
    if @enviroment.deep.method_defined? :add_members_from_file
      @enviroment.deep.new.add_members_from_file(@enviroment.client, @enviroment.config, params[0])
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  # Remove member from oranization.
  # @param [Array<String>] params path to JSON file containing members to be removed or Regexp to match members
  #   to be removed. file_templates contains a template for this command.
  def remove_member(params)
    if @enviroment.deep.method_defined? :delete_member
      @enviroment.deep.new.delete_member(@enviroment.client, @enviroment.config, params[0])
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end
  
  # Invite outside collaborators of an organization to be members of that organization.
  # @param [Array<String>] params path to file or Regexp to match outside collaborators to be invited.
  #   file_templates contains a JSON template for this command.
  def invite_outside_collaborators(params)
    if @enviroment.deep.method_defined? :invite_all_outside_collaborators
      @enviroment.deep.new.invite_all_outside_collaborators(@enviroment.client, @enviroment.config, params[0])
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  # Exit Github Education Shell CLI saving configuration. When user runs the CLI again, configuration
  # and context are restored from last session. However, previous contexts are not restored, only last one.
  def exit(_params)
    @enviroment.sysbh.save_memory(@enviroment.config_path, @enviroment.config)
    @enviroment.sysbh.save_cache(@enviroment.config_path, @enviroment.config)
    @enviroment.sysbh.remove_temp("#{ENV['HOME']}/.ghedsh/temp")

    0
  end

  # Runs a bash command.
  # @param [Array<String>] params bash command to perform
  def bash(params)
    bash_command = params.join(' ')
    system(bash_command)
  end

  # Open info depending on context. Within organization will open GitHub organization profile, member profile, etc. 
  def open(params)
    if @enviroment.deep.method_defined? :open_info
      @enviroment.deep.new.open_info(@enviroment.config, params[0], @enviroment.client)
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
  end

  # Create new repository with the provided name. Two modes are available: fast and custom. Fast mode creates a public repo.
  # Custom mode allows to set several details, like privacy, description, .gitignore template, etc.
  #
  # @param [Array<String>] params repository name
  def new_repo(params)
    if @enviroment.deep.method_defined? :create_repo
      begin
        repo_name = params[0]
        options = repo_creation_guide
        if options == 'Default'
          @enviroment.deep.new.create_repo(@enviroment, repo_name, options = {})
        else
          @enviroment.deep.new.create_repo(@enviroment, repo_name, options)
        end
      rescue StandardError => exception
        puts Rainbow(exception.message.to_s).color('#cc0000')
      end
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  # Remove repository
  #
  # @param [Array<String>] params repository name to be deleted
  def rm_repo(params)
    if @enviroment.deep.method_defined? :remove_repo
      @enviroment.deep.new.remove_repo(@enviroment, params[0])
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  # Change repository to private.
  #
  # @param [Array<String>] params Regexp to match repositories and edit its privacy
  def set_private(params)
    if @enviroment.deep.method_defined? :change_to_private_repo
      @enviroment.deep.new.change_to_private_repo(@enviroment.client, @enviroment.config, params[0])
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  # Change repository to public
  #
  # @param [Array<String>] params Regexp to match repositories and edit its privacy
  def set_public(params)
    if @enviroment.deep.method_defined? :change_to_public_repo
      @enviroment.deep.new.change_to_public_repo(@enviroment.client, @enviroment.config, params[0])
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  # Clone repository
  #
  # @param [Array<String>] params Regexp to match repositories to be cloned or individual repository to be cloned.
  #   Second parameter is custom path to find cloned repositories. If not provided CWD is the path.
  def clone_repo(params)
    if @enviroment.deep.method_defined? :clone_repository
      @enviroment.deep.new.clone_repository(@enviroment, params[0], params[1])
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
  end

  # Delete cloned repository
  def delete_cloned_repos(_params)
    ####### FileUtils.remove_entry_secure("", force = true)
    puts Rainbow("Cloned content deleted.\n").color('#00529B')
  end

  # Display commits
  #
  # @param [Array<String>] params repository name and baranch. If user is already inside a repository, a branch
  # can be specified, if not 'master' is default branch.
  def display_commits(params)
    if @enviroment.deep.method_defined? :show_commits
      @enviroment.deep.new.show_commits(@enviroment, params)
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  # Display a table with GitHub IDs and membership type within an prganization
  #
  # @param [Array<String>] params Regexp to show matching people, if empty, shows all people.
  def display_people(params)
    if @enviroment.deep.method_defined? :show_people
      @enviroment.deep.new.show_people(@enviroment.client, @enviroment.config, params[0])
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end
  
  # Show teams within an organization
  #
  # @param [Array<String>] params Regexp to show matching teams
  def display_teams(params)
    if @enviroment.deep.method_defined? :show_teams
      @enviroment.deep.new.show_teams(@enviroment.client, @enviroment.config, params[0])
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  # Create teams from file or by name
  #
  # @param [Array<String>] params path to JSON template or team name to be created
  def new_team(params)
    if @enviroment.deep.method_defined? :create_team
      @enviroment.deep.new.create_team(@enviroment.client, @enviroment.config, params[0])
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  # Remove team
  def rm_team(_params)
    if @enviroment.deep.method_defined? :remove_team
      @enviroment.deep.new.remove_team(@enviroment.config)
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  # Open repository issue creation form URL
  def new_issue(_params)
    if @enviroment.deep.method_defined? :create_issue
      @enviroment.deep.new.create_issue(@enviroment.config)
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
  end

  # Open browser with active issues URL
  def display_issues(_params)
    if @enviroment.deep.method_defined? :show_issues
      @enviroment.deep.new.show_issues(@enviroment.config)
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
  end

  # Display respositories
  #
  # @param [Array<String>] param Regexp to show matchin repository names. If not provided, show all
  def display_repos(params)
    if @enviroment.deep.method_defined? :show_repos
      @enviroment.deep.new.show_repos(@enviroment.client, @enviroment.config, params[0])
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  # Clear screen
  def clear(_params)
    system('clear')
  end

  def orgsn(params)
    #     params[0].prepend("/")
    #     file_path = "#{Dir.home}#{params[0]}"
    #     p file_path[0]
    #     p file_path = file_path.delete('"')
    #     puts File.file?(file_path) ? true : false
  end

  # Change CLI context and move between repositories, organization, teams
  # Contexts are stored in a stack
  # @param [Array<String>] params cd operation
  # @example change to organization
  #   User > cd org /regexp/
  # @example change to repository
  #   User > Org > cd repo /regexp/ or String
  def change_context(params)
    if params.empty?
      @enviroment.config['Org'] = nil
      @enviroment.config['Repo'] = nil
      @enviroment.config['Team'] = nil
      @enviroment.config['TeamID'] = nil
      @enviroment.config['Assig'] = nil

      @context_stack.clear
      @context_stack.push(@default_enviroment)

      @enviroment.deep = User
    elsif params[0] == '..'
      if @context_stack.size > 1
        @context_stack.pop
        stack_pointer = @context_stack.last

        @enviroment.config = stack_pointer.config
        @enviroment.deep = stack_pointer.deep
      else
        @enviroment.config = @default_enviroment.config
        @enviroment.deep = @default_enviroment.deep
      end
    else
      begin
      name = params[1]
      name = name.gsub(/\A("|')|("|')\Z/, '')
      name.insert(0, '\'')
      name.insert(-1, '\'')
      action = @enviroment.deep.new.build_cd_syntax(params[0], name)
      env = OpenStruct.new
      env.config = Marshal.load(Marshal.dump(@enviroment.config))
      env.deep = @enviroment.deep
      client = @enviroment.client
      changed_enviroment = eval(action)
      unless changed_enviroment.nil?
        current_enviroment = OpenStruct.new
        current_enviroment.config = changed_enviroment.config
        current_enviroment.deep = changed_enviroment.deep
        @context_stack.push(current_enviroment)
        @enviroment.config = changed_enviroment.config
        @enviroment.deep = changed_enviroment.deep
      end
    rescue StandardError => exception
      puts Rainbow(exception.message).color('#D8000C')
    rescue SyntaxError => err
      puts Rainbow('Syntax Error typing the command. Tip: cd <type> <Regexp|String>').color('#cc0000')
      puts Rainbow('Regexp options for Ruby: /i, /m, /x, /o').color('#cc0000')
      puts
    end
    end
  end
end
