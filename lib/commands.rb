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

  # Go back to any level
  def cdback(returnall)
    if returnall != true
      if @enviroment.deep == ORGS
        @enviroment.config['Org'] = nil
        @enviroment.deep = 1
        @orgs_repos = []
      elsif @enviroment.deep == ORGS_REPO
        if @enviroment.repo_path == ''
          @enviroment.config['Repo'] = nil
          @enviroment.deep = 2
        else
          aux = @enviroment.repo_path.split('/')
          aux.pop
          @enviroment.repo_path = if aux.empty?
                                    ''
                                  else
                                    aux.join('/')
                       end
        end
      elsif @enviroment.deep == USER_REPO
        if @enviroment.repo_path == ''
          @enviroment.config['Repo'] = nil
          @enviroment.deep = 1
        else
          aux = @enviroment.repo_path.split('/')
          aux.pop
          @enviroment.repo_path = if aux.empty?
                                    ''
                                  else
                                    aux.join('/')
                       end
        end
      elsif @enviroment.deep == TEAM
        @enviroment.config['Team'] = nil
        @enviroment.config['TeamID'] = nil
        @teams_repos = []
        @enviroment.deep = ORGS
      elsif @enviroment.deep == ASSIG
        @enviroment.deep = ORGS
        @enviroment.config['Assig'] = nil
      elsif @enviroment.deep == TEAM_REPO
        if @enviroment.repo_path == ''
          @enviroment.config['Repo'] = nil
          @enviroment.deep = TEAM
        else
          aux = @enviroment.repo_path.split('/')
          aux.pop
          @enviroment.repo_path = if aux.empty?
                                    ''
                                  else
                                    aux.join('/')
                       end
        end
      end
    else
      @enviroment.config['Org'] = nil
      @enviroment.config['Repo'] = nil
      @enviroment.config['Team'] = nil
      @enviroment.config['TeamID'] = nil
      @enviroment.config['Assig'] = nil
      @enviroment.deep = USER
      @orgs_repos = []; @teams_repos = []
      @enviroment.repo_path = ''
    end
  end

  # Go to the path, depends with the scope
  # if you are in user scope, first searchs Orgs then Repos, etc.
  def cd(path)
    if @enviroment.deep == ORGS_REPO || @enviroment.deep == USER_REPO || @enviroment.deep == TEAM_REPO
      cdrepo(path)
    end
    o = Organizations.new
    path_split = path.split('/')
    if path_split.size == 1 # #cd con path simple
      if @enviroment.deep == USER
        @orgs_list = o.read_orgs(@enviroment.client)
        aux = @orgs_list
        if aux.one? { |aux| aux == path }
          @enviroment.config['Org'] = path
          @teamlist = Teams.new.read_teamlist(@enviroment.client, @enviroment.config)
          @sysbh.add_history_str(2, o.get_assigs(@enviroment.client, @enviroment.config, false))
          @sysbh.add_history_str(1, @teamlist)
          @enviroment.deep = 2
        else
          # puts "\nNo organization is available with that name"
          set(path)
        end
      elsif @enviroment.deep == ORGS
        @teamlist = Teams.new.read_teamlist(@enviroment.client, @enviroment.config) if @teamlist == []
        aux = @teamlist

        if !aux[path].nil?
          @enviroment.config['Team'] = path
          @enviroment.config['TeamID'] = @teamlist[path]
          @enviroment.deep = TEAM
        else
          # puts "\nNo team is available with that name"
          set(path) if cdassig(path) == false
        end
      elsif @enviroment.deep == TEAM
        set(path)
      end
    end
  end

  # set in the given path repository, first search in the list, then do the github query if list is empty
  def set(path)
    reposlist = Repositories.new

    if @enviroment.deep == USER
      @enviroment.config['Repo'] = path
      reposlist = if @repos_list.empty? == false
                    @repos_list
                  else
                    reposlist.get_repos_list(@enviroment.client, @enviroment.config, @enviroment.deep)
                  end
      if reposlist.one? { |aux| aux == path }
        @enviroment.deep = USER_REPO
        puts "Set in #{@enviroment.config['User']} repository: #{path}\n\n"
      end
    elsif @enviroment.deep == ORGS

      reposlist = if @orgs_repos.empty? == false
                    @orgs_repos
                  else
                    reposlist.get_repos_list(@enviroment.client, @enviroment.config, @enviroment.deep)
                  end
      if reposlist.one? { |aux| aux == path }
        @enviroment.config['Repo'] = path
        @enviroment.deep = ORGS_REPO
        puts "Set in #{@enviroment.config['Org']} repository: #{path}\n\n"
      end
    elsif @enviroment.deep == TEAM

      reposlist = if @teams_repos.empty? == false
                    @teams_repos
                  else
                    reposlist.get_repos_list(@enviroment.client, @enviroment.config, @enviroment.deep)
                  end
      if reposlist.one? { |aux| aux == path }
        @enviroment.config['Repo'] = path
        @enviroment.deep = TEAM_REPO
        puts "Set in #{@enviroment.config['Team']} repository: #{path}\n\n"
      end
    end
    # if @enviroment.deep==USER || @enviroment.deep==ORGS || @enviroment.deep==TEAM then puts "No repository is available with that name\n\n" end
    if @enviroment.deep == USER || @enviroment.deep == ORGS || @enviroment.deep == TEAM
      puts "\nNo organization is available with that name"
      puts "\nNo team is available with that name"
      puts "No repository is available with that name\n\n"
    end
  end

  def cdrepo(path)
    r = Repositories.new
    list = []

    newpath = if @enviroment.repo_path == ''
                path
              else
                @enviroment.repo_path + '/' + path
              end
    list = r.get_files(@enviroment.client, @enviroment.config, newpath, false, @enviroment.deep)
    if list.nil?
      puts 'Wrong path name'
    else
      @enviroment.repo_path = newpath
    end
  end

  def cdassig(path)
    o = Organizations.new
    list = o.get_assigs(@enviroment.client, @enviroment.config, true)
    if list.one? { |aux| aux == path }
      @enviroment.deep = ASSIG
      puts "Set in #{@enviroment.config['Org']} assignment: #{path}\n\n"
      @enviroment.config['Assig'] = path
      return true
    else
      puts 'No assignment is available with that name'
      return false
    end
  end

  # def orgs
  # if @enviroment.deep == USER
  # @sysbh.add_history_str(2, Organizations.new.show_orgs(@enviroment.client, @enviroment.config))
  # elsif @enviroment.deep == ORGS
  # Organizations.new.show_orgs(@enviroment.client, @enviroment.config)
  # end
  # end

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
