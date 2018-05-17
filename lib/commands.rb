require 'version'
require 'common'
require 'ostruct'
require 'fileutils'

class Commands
  attr_reader :enviroment

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
    add_command('rm_team', method(:rm_team))
    add_command('clone', method(:clone_repo))
    add_command('rm_cloned', method(:delete_cloned_repos))
    add_command('commits', method(:display_commits))
    add_command('orgs', method(:display_orgs))
    add_command('invite_member', method(:invite_member))
    add_command('invite_member_from_file', method(:invite_member_from_file))
    add_command('invite_outside_collaborators', method(:invite_outside_collaborators))
    add_command('people', method(:display_people))
    add_command('teams', method(:display_teams))
    add_command('orgsn', method(:orgsn))
    add_command('cd', method(:change_context))
    add_command('get', method(:get))
    add_command('open', method(:open))
    add_command('bash', method(:bash))
  end

  def add_command(command_name, command)
    COMMANDS[command_name] = command
  end

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

  def display_orgs(params)
    if @enviroment.deep.method_defined? :show_organizations
      @enviroment.deep.new.show_organizations(@enviroment.client, params)
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  def invite_member(params)
    if @enviroment.deep.method_defined? :add_member
      @enviroment.deep.new.add_members(@enviroment.client, @enviroment.config, params)
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  def invite_member_from_file(params)
    if @enviroment.deep.method_defined? :add_members_from_file
      @enviroment.deep.new.add_members_from_file(@enviroment.client, @enviroment.config, params[0])
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  def invite_outside_collaborators(params)
    if @enviroment.deep.method_defined? :invite_all_outside_collaborators
      @enviroment.deep.new.invite_all_outside_collaborators(@enviroment.client, @enviroment.config, params[0])
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  def exit(_params)
    @enviroment.sysbh.save_memory(@enviroment.config_path, @enviroment.config)
    @enviroment.sysbh.save_cache(@enviroment.config_path, @enviroment.config)
    @enviroment.sysbh.remove_temp("#{ENV['HOME']}/.ghedsh/temp")

    0
  end

  def get(org_name)
    # puts RbConfig::CONFIG['host_os']
    # prueba-classroom
    spinner = custom_spinner('Getting file from remote server ...')
    uri = "http://codelab-tfg1718.herokuapp.com/ghedsh/#{org_name[0]}"
    res = Net::HTTP.get_response(URI(uri))
    fich = JSON.parse(res.body)
    fich.each do |item|
      puts item['name']
    end
  end

  def bash(params)
    bash_command = params.join(' ')
    system(bash_command)
  end

  def open(params)
    if @enviroment.deep.method_defined? :open_info
      @enviroment.deep.new.open_info(@enviroment.config, params[0], @enviroment.client)
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
  end

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

  def rm_repo(params)
    if @enviroment.deep.method_defined? :remove_repo
      @enviroment.deep.new.remove_repo(@enviroment, params[0])
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  def clone_repo(params)
    if @enviroment.deep.method_defined? :clone_repository
      @enviroment.deep.new.clone_repository(@enviroment, params[0], params[1])
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
  end

  def delete_cloned_repos(_params)
    FileUtils.remove_entry_secure("#{Dir.home}/ghedsh_cloned", force = true)
    puts Rainbow("Cloned content deleted.\n").color('#00529B')
  end

  def display_commits(params)
    if @enviroment.deep.method_defined? :show_commits
      @enviroment.deep.new.show_commits(@enviroment, params)
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  def display_people(params)
    if @enviroment.deep.method_defined? :show_people
      @enviroment.deep.new.show_people(@enviroment.client, @enviroment.config, params[0])
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  def display_teams(params)
    if @enviroment.deep.method_defined? :show_teams
      @enviroment.deep.new.show_teams(@enviroment.client, @enviroment.config, params[0])
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  def new_team(params)
    if @enviroment.deep.method_defined? :create_team
      @enviroment.deep.new.create_team(@enviroment.client, @enviroment.config, params[0])
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  def rm_team(_params)
    if @enviroment.deep.method_defined? :remove_team
      @enviroment.deep.new.remove_team(@enviroment.config)
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  def new_issue(_params)
    if @enviroment.deep.method_defined? :create_issue
      @enviroment.deep.new.create_issue(@enviroment.config)
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
  end

  def display_issues(_params)
    if @enviroment.deep.method_defined? :show_issues
      @enviroment.deep.new.show_issues(@enviroment.config)
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
  end

  def display_repos(params)
    if @enviroment.deep.method_defined? :show_repos
      @enviroment.deep.new.show_repos(@enviroment.client, @enviroment.config, params[0])
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").color(WARNING_CODE)
    end
    puts
  end

  def clear(_params)
    system('clear')
  end

  def orgsn(params)
  end

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
      action = @enviroment.deep.new.build_cd_syntax(params[0], params[1])
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
