require 'version'
require 'common'

class Commands
  attr_accessor :enviroment
  attr_reader :previous_config

  attr_reader :orgs_list
  attr_reader :repos_list
  attr_reader :teamlist
  attr_reader :orgs_repos
  attr_reader :teams_repos
  attr_reader :issues_list

  def initialize
    @repos_list = []; @orgs_repos = []; @teams_repos = []; @orgs_list = []; @teamlist = []
    add_command('clear', method(:clear))
    add_command('repos', method(:repos))
    add_command('help', method(:help))
    add_command('exit', method(:exit))
    add_command('new_repo', method(:new_repo))
    add_command('commits', method(:display_commits))
    add_command('orgs', method(:orgs))
    add_command('orgsn', method(:orgsn))
    add_command('cd', method(:change_context))
  end

  def add_command(command_name, command)
    COMMANDS[command_name] = command
  end

  def load_enviroment(console_enviroment)
    @enviroment = console_enviroment
  end

  def help(opcd)
    h = HelpM.new
    if opcd.size >= 1
      h.context(opcd[0..opcd.size - 1], @enviroment.deep)
    else
      if @enviroment.deep == USER
        h.user
      elsif @enviroment.deep == ORG
        h.org
      elsif @enviroment.deep == ORGS_REPO
        h.org_repo
      elsif @enviroment.deep == USER_REPO
        h.user_repo
      elsif @enviroment.deep == TEAM
        h.orgs_teams
      elsif @enviroment.deep == TEAM_REPO
        h.team_repo
      elsif @enviroment.deep == ASSIG
        h.asssig
      end
    end
  rescue StandardError => exception
    puts exception
  end

  def orgs(_params)
    @enviroment.deep.new.show_organizations(@enviroment.client, @enviroment.config)
  end

  def people
    if @enviroment.deep == ORGS
      @sysbh.add_history_str(2, Organizations.new.show_organization_members_bs(@enviroment.client, @enviroment.config))
    elsif @enviroment.deep == TEAM
      @sysbh.add_history_str(2, Teams.new.show_team_members_bs(@enviroment.client, @enviroment.config))
    end
  end

  def repos(params)
    puts "parametros del comando repos #{params}"
    repo = Repositories.new
    if @enviroment.deep == USER
      if @repos_list.empty?
        if all == false
          list = repo.show_repos(@enviroment.client, @enviroment.config, USER, nil)
          @sysbh.add_history_str(2, list)
          @repos_list = list
        else
          list = repo.get_repos_list(@enviroment.client, @enviroment.config, USER)
          @sysbh.add_history_str(2, list)
          @repos_list = list
          puts list
        end
      else
        @sysbh.showcachelist(@repos_list, nil)
      end
    elsif @enviroment.deep == ORG
      if @orgs_repos.empty?
        if all == false
          list = repo.show_repos(@enviroment.client, @enviroment.config, ORG, nil)
          @sysbh.add_history_str(2, list)
          @orgs_repos = list
        else
          # list=repo.show_repos(@enviroment.client,@enviroment.config,ORGS)
          list = repo.get_repos_list(@enviroment.client, @enviroment.config, ORG)
          @sysbh.add_history_str(2, list)
          @orgs_repos = list
          puts list
        end
      else
        @sysbh.showcachelist(@orgs_repos, nil)
      end
    elsif @enviroment.deep == TEAM
      if @teams_repos.empty?
        if all == false
          list = repo.show_repos(@enviroment.client, @enviroment.config, TEAM, nil)
          @sysbh.add_history_str(2, list)
          @teams_repos = list
        else
          list = repo.show_repos(@enviroment.client, @enviroment.config, TEAM)
          @sysbh.add_history_str(2, list)
          @repos_list = list
          puts list
        end
      else
        @sysbh.showcachelist(@teams_repos, nil)
      end
    end
  end

  def get_teamlist(data)
    list = []
    for i in 0..data.size - 1
      list.push(@teamlist[data[i]])
    end
    list
  end

  def commits
    c = Repositories.new
    if @enviroment.deep == ORGS_REPO || @enviroment.deep == USER_REPO || @enviroment.deep == TEAM_REPO
      c.show_commits(@enviroment.client, @enviroment.config, @enviroment.deep)
    end
    print "\n"
  end

  def show_forks
    c = Repositories.new
    if @enviroment.deep == ORGS_REPO || @enviroment.deep == USER_REPO || @enviroment.deep == TEAM_REPO
      c.show_forks(@enviroment.client, @enviroment.config, @enviroment.deep)
    end
  end

  def collaborators
    c = Repositories.new
    if @enviroment.deep == ORGS_REPO || @enviroment.deep == USER_REPO || @enviroment.deep == TEAM_REPO
      c.show_collaborators(@enviroment.client, @enviroment.config, @enviroment.deep)
    end
  end

  def exit(_params)
    @enviroment.sysbh.save_memory(@enviroment.config_path, @enviroment.config)
    @enviroment.sysbh.save_cache(@enviroment.config_path, @enviroment.config)
    @enviroment.sysbh.remove_temp("#{ENV['HOME']}/.ghedsh/temp")

    0
  end

  def new_repo(params)
    # puts "HOLA"
    # puts params
    # options = Hash[*params.flatten]
    # puts "opciones: #{options}"
    # puts a

    # opts = {}
    # opts[:has_issues] = ""
    # opts[:has_wiki] = ""
    # opts[:private] = "true"
    # @enviroment.client.create_repository('prueba', opts)
  end

  def display_commits(params)
    if @enviroment.deep.method_defined? :show_commits
      @enviroment.deep.new.show_commits(@enviroment, params)
    else
      puts "Command not available in context \"#{@enviroment.deep.name}\""
    end
    puts
  end

  def clear(_params)
    system('clear')
  end

  def orgsn(_params)
    puts "EL DEEP: #{@enviroment.deep}"

    p @enviroment.config
  end

  def get_previous_config
    @previous_config
  end

  def change_context(params)
    if params.empty?
      @enviroment.config['Org'] = nil
      @enviroment.config['Repo'] = nil
      @enviroment.config['Team'] = nil
      @enviroment.config['TeamID'] = nil
      @enviroment.config['Assig'] = nil

      @enviroment.deep = USER
    else
      path = params[0].split('/')
      clean_path = path.reject(&:empty?)
      p clean_path[0]
      # quitar los valores nil para comprobar los que tienen valor asignado
      actual_config = @enviroment.config.compact

      if actual_config['User'] && actual_config['Org']
        if @enviroment.client.repository?("#{@enviroment.config['Org']}/#{clean_path[0]}")
          @enviroment.config['Repo'] = clean_path[0]
        end
      else
        if @enviroment.client.repository?("#{@enviroment.client.login}/#{clean_path[0]}")
          puts 'seteo el repo'
          @enviroment.config['Repo'] = clean_path[0]
          @enviroment.deep = USER
        elsif @enviroment.client.organization_member?(clean_path[0], @enviroment.client.login)
          puts 'seteo la org'
          @enviroment.config['Org'] = clean_path[0]
          @enviroment.deep = ORG
          clean_path.shift
          unless clean_path.empty?
            if @enviroment.client.repository?("#{@enviroment.config['Org']}/#{clean_path[0]}")
              @enviroment.config['Repo'] = clean_path[0]
            else
              puts "#{"\u26A0".encode('utf-8')} #{Rainbow("Repo ''#{clean_path[0]}'' does not exist within org #{@enviroment.config['Org']}").yellow.underline}"
            end
          end
        else
          puts "#{"\u26A0".encode('utf-8')} #{Rainbow("You are currently not a ''#{clean_path[0]}'' org member or ''#{clean_path[0]}'' is not a repo.").yellow.underline}"
        end
      end
      # la idea para ir para atras es comprobar si clean_path[0].include?('..')
      #  tener en otra variable los valores config y deep pasados (es posible?)
      #         if @enviroment.client.repository?("#{@enviroment.client.login}/#{clean_path[0]}")
      #           puts 'seteo el repo'
      #           @enviroment.config['Repo'] = clean_path[0]
      #           @enviroment.deep = USER
      #         end
      #         # devuelve array con las organizaciones a las que pertenece el usuario autenticado
      #         #user_orgs = []
      #         #@enviroment.client.organizations.each do |it|
      #           #user_orgs << it[:login]
      #         #end
      #         #user_orgs.include?(clean_path[0])
      #         if @enviroment.client.organization_member?(clean_path[0], @enviroment.client.login)
      #           puts 'seteo la org'
      #           @enviroment.config['Org'] = clean_path[0]
      #           @enviroment.deep = ORG
      #           clean_path.shift
      #           unless clean_path.empty?
      #             if @enviroment.client.repository?("#{@enviroment.config['Org']}/#{clean_path[0]}")
      #               @enviroment.config['Repo'] = clean_path[0]
      #             end
      #           end
      #         end
      #       #end
      # unless @enviroment.client.organization_member?(path, @enviroment.client.login)
      # puts "#{"\u26A0".encode('utf-8')} #{Rainbow("You are currently not a #{@enviroment.config['Org']} member.").yellow.underline}"
      # end
      # end
    end
  end
end
