require 'require_all'
require 'json'
require 'readline'
require 'octokit'
require 'optparse'
require 'actions/help'
require 'actions/orgs'
require 'actions/repo'
require 'actions/system'
require 'actions/teams'
require 'actions/user'
require 'version'
require 'commands'

USER = 1
ORGS = 2
USER_REPO = 10
ORGS_REPO = 3
TEAM = 4
ASSIG = 6
TEAM_REPO = 5

class Interface
  attr_accessor :option, :sysbh
  attr_accessor :config, :commands
  attr_accessor :client
  attr_accessor :deep
  attr_reader :orgs_list, :repos_list, :teamlist, :orgs_repos, :teams_repos, :repo_path, :issues_list

  def initialize
    @sysbh = Sys.new
    @repos_list = []; @orgs_repos = []; @teams_repos = []; @orgs_list = []; @teamlist = []
    @repo_path = ''
    @commands = {}
    # @shell_commands = Commands.new(self)
  end

  def parse
    options = { user: nil, token: nil, path: nil }

    parser = OptionParser.new do |opts|
      opts.banner = "Usage: ghedsh [options]\nWith no options it runs with default configuration. Configuration files are being set in #{ENV['HOME']}/.ghedsh\n"
      opts.on('-t', '--token token', 'Provides a github access token by argument.') do |token|
        options[:token] = token
      end
      opts.on('-c', '--configpath path', 'Give your own path for GHEDSH configuration files') do |path|
        options[:configpath] = path
      end
      opts.on('-u', '--user user', 'Change your user from your users list') do |user|
        options[:user] = user
      end
      opts.on('-v', '--version', 'Show the current version of GHEDSH') do
        puts "GitHub Education Shell v#{Ghedsh::VERSION}"
        exit
      end
      opts.on('-h', '--help', 'Displays Help') do
        puts opts
        exit
      end
    end

    begin
      parser.parse!
    rescue StandardError
      puts 'Argument error. Use ghedsh -h or ghedsh --help for more information about the usage of this program'
      exit
    end
    options
  end

  def start
    options = parse

    trap('SIGINT') { puts; throw :ctrl_c }

    catch :ctrl_c do
      begin
        if options[:user].nil? && options[:token].nil? && !options[:path].nil?
          run(options[:path], options[:token], options[:user])
        else
          run("#{ENV['HOME']}/.ghedsh", options[:token], options[:user])
        end
      rescue SystemExit, Interrupt
        raise
      rescue Exception => e
        puts 'exit'
        puts e
      end
    end
  end

  def prompt
    if @deep == USER then @config['User'] + '> '
    elsif @deep == USER_REPO
      if @repo_path != ''
        @config['User'] + '>' + "\e[31m#{@config['Repo']}\e[0m" + '>' + @repo_path.to_s + '> '
      else
        @config['User'] + '>' + "\e[31m#{@config['Repo']}\e[0m" + '> '
      end
    elsif @deep == ORGS then @config['User'] + '>' + "\e[34m#{@config['Org']}\e[0m" + '> '
    elsif @deep == ASSIG then @config['User'] + '>' + "\e[34m#{@config['Org']}\e[0m" + '>' + "\e[35m#{@config['Assig']}\e[0m" + '> '
    elsif @deep == TEAM then @config['User'] + '>' + "\e[34m#{@config['Org']}\e[0m" + '>' + "\e[32m#{@config['Team']}\e[0m" + '> '
    elsif @deep == TEAM_REPO
      if @repo_path != ''
        @config['User'] + '>' + "\e[34m#{@config['Org']}\e[0m" + '>' + "\e[32m#{@config['Team']}\e[0m" + '>' + "\e[31m#{@config['Repo']}\e[0m" + '>' + @repo_path.to_s + '> '
      else
        @config['User'] + '>' + "\e[34m#{@config['Org']}\e[0m" + '>' + "\e[32m#{@config['Team']}\e[0m" + '>' + "\e[31m#{@config['Repo']}\e[0m" + '> '
      end
    elsif @deep == ORGS_REPO
      if @repo_path != ''
        @config['User'] + '>' + "\e[34m#{@config['Org']}\e[0m" + '>' + "\e[31m#{@config['Repo']}\e[0m" + '>' + @repo_path.to_s + '> '
      else
        @config['User'] + '>' + "\e[34m#{@config['Org']}\e[0m" + '>' + "\e[31m#{@config['Repo']}\e[0m" + '> '
      end
    end
  end

  def help(opcd)
    h = HelpM.new
    if opcd.size > 1
      h.context(opcd[1..opcd.size - 1], @deep)
    else
      if @deep == USER
        h.user
      elsif @deep == ORGS
        h.org
      elsif @deep == ORGS_REPO
        h.org_repo
      elsif @deep == USER_REPO
        h.user_repo
      elsif @deep == TEAM
        h.orgs_teams
      elsif @deep == TEAM_REPO
        h.team_repo
      elsif @deep == ASSIG
        h.asssig
      end
    end
  end

  # Go back to any level
  def cdback(returnall)
    if returnall != true
      if @deep == ORGS
        @config['Org'] = nil
        @deep = 1
        @orgs_repos = []
      elsif @deep == ORGS_REPO
        if @repo_path == ''
          @config['Repo'] = nil
          @deep = 2
        else
          aux = @repo_path.split('/')
          aux.pop
          @repo_path = if aux.empty?
                         ''
                       else
                         aux.join('/')
                       end
        end
      elsif @deep == USER_REPO
        if @repo_path == ''
          @config['Repo'] = nil
          @deep = 1
        else
          aux = @repo_path.split('/')
          aux.pop
          @repo_path = if aux.empty?
                         ''
                       else
                         aux.join('/')
                       end
        end
      elsif @deep == TEAM
        @config['Team'] = nil
        @config['TeamID'] = nil
        @teams_repos = []
        @deep = ORGS
      elsif @deep == ASSIG
        @deep = ORGS
        @config['Assig'] = nil
      elsif @deep == TEAM_REPO
        if @repo_path == ''
          @config['Repo'] = nil
          @deep = TEAM
        else
          aux = @repo_path.split('/')
          aux.pop
          @repo_path = if aux.empty?
                         ''
                       else
                         aux.join('/')
                       end
        end
      end
    else
      @config['Org'] = nil
      @config['Repo'] = nil
      @config['Team'] = nil
      @config['TeamID'] = nil
      @config['Assig'] = nil
      @deep = 1
      @orgs_repos = []; @teams_repos = []
      @repo_path = ''
    end
  end

  # Go to the path, depends with the scope
  # if you are in user scope, first searchs Orgs then Repos, etc.
  def cd(path)
    if @deep == ORGS_REPO || @deep == USER_REPO || @deep == TEAM_REPO
      cdrepo(path)
    end
    o = Organizations.new
    path_split = path.split('/')
    if path_split.size == 1 # #cd con path simple
      if @deep == USER
        @orgs_list = o.read_orgs(@client)
        aux = @orgs_list
        if aux.one? { |aux| aux == path }
          @config['Org'] = path
          @teamlist = Teams.new.read_teamlist(@client, @config)
          @sysbh.add_history_str(2, o.get_assigs(@client, @config, false))
          @sysbh.add_history_str(1, @teamlist)
          @deep = 2
        else
          # puts "\nNo organization is available with that name"
          set(path)
        end
      elsif @deep == ORGS
        @teamlist = Teams.new.read_teamlist(@client, @config) if @teamlist == []
        aux = @teamlist

        if !aux[path].nil?
          @config['Team'] = path
          @config['TeamID'] = @teamlist[path]
          @deep = TEAM
        else
          # puts "\nNo team is available with that name"
          set(path) if cdassig(path) == false
        end
      elsif @deep == TEAM
        set(path)
      end
    end
  end

  # set in the given path repository, first search in the list, then do the github query if list is empty
  def set(path)
    reposlist = Repositories.new

    if @deep == USER
      @config['Repo'] = path
      reposlist = if @repos_list.empty? == false
                    @repos_list
                  else
                    reposlist.get_repos_list(@client, @config, @deep)
                  end
      if reposlist.one? { |aux| aux == path }
        @deep = USER_REPO
        puts "Set in #{@config['User']} repository: #{path}\n\n"
      end
    elsif @deep == ORGS

      reposlist = if @orgs_repos.empty? == false
                    @orgs_repos
                  else
                    reposlist.get_repos_list(@client, @config, @deep)
                  end
      if reposlist.one? { |aux| aux == path }
        @config['Repo'] = path
        @deep = ORGS_REPO
        puts "Set in #{@config['Org']} repository: #{path}\n\n"
      end
    elsif @deep == TEAM

      reposlist = if @teams_repos.empty? == false
                    @teams_repos
                  else
                    reposlist.get_repos_list(@client, @config, @deep)
                  end
      if reposlist.one? { |aux| aux == path }
        @config['Repo'] = path
        @deep = TEAM_REPO
        puts "Set in #{@config['Team']} repository: #{path}\n\n"
      end
    end
    # if @deep==USER || @deep==ORGS || @deep==TEAM then puts "No repository is available with that name\n\n" end
    if @deep == USER || @deep == ORGS || @deep == TEAM
      puts "\nNo organization is available with that name"
      puts "\nNo team is available with that name"
      puts "No repository is available with that name\n\n"
    end
  end

  def cdrepo(path)
    r = Repositories.new
    list = []

    newpath = if @repo_path == ''
                path
              else
                @repo_path + '/' + path
              end
    list = r.get_files(@client, @config, newpath, false, @deep)
    if list.nil?
      puts 'Wrong path name'
    else
      @repo_path = newpath
    end
  end

  def cdassig(path)
    o = Organizations.new
    list = o.get_assigs(@client, @config, true)
    if list.one? { |aux| aux == path }
      @deep = ASSIG
      puts "Set in #{@config['Org']} assignment: #{path}\n\n"
      @config['Assig'] = path
      return true
    else
      puts 'No assignment is available with that name'
      return false
    end
  end

  def orgs
    if @deep == USER
      @sysbh.add_history_str(2, Organizations.new.show_orgs(@client, @config))
    elsif @deep == ORGS
      Organizations.new.show_orgs(@client, @config)
    end
  end

  def people
    if @deep == ORGS
      @sysbh.add_history_str(2, Organizations.new.show_organization_members_bs(@client, @config))
    elsif @deep == TEAM
      @sysbh.add_history_str(2, Teams.new.show_team_members_bs(@client, @config))
    end
  end

  def repos(all)
    repo = Repositories.new
    if @deep == USER
      if @repos_list.empty?
        if all == false
          list = repo.show_repos(@client, @config, USER, nil)
          @sysbh.add_history_str(2, list)
          @repos_list = list
        else
          list = repo.get_repos_list(@client, @config, USER)
          @sysbh.add_history_str(2, list)
          @repos_list = list
          puts list
        end
      else
        @sysbh.showcachelist(@repos_list, nil)
      end
    elsif @deep == ORGS
      if @orgs_repos.empty?
        if all == false
          list = repo.show_repos(@client, @config, ORGS, nil)
          @sysbh.add_history_str(2, list)
          @orgs_repos = list
        else
          # list=repo.show_repos(@client,@config,ORGS)
          list = repo.get_repos_list(@client, @config, ORGS)
          @sysbh.add_history_str(2, list)
          @orgs_repos = list
          puts list
        end
      else
        @sysbh.showcachelist(@orgs_repos, nil)
      end
    elsif @deep == TEAM
      if @teams_repos.empty?
        if all == false
          list = repo.show_repos(@client, @config, TEAM, nil)
          @sysbh.add_history_str(2, list)
          @teams_repos = list
        else
          list = repo.show_repos(@client, @config, TEAM)
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
    if @deep == ORGS_REPO || @deep == USER_REPO || @deep == TEAM_REPO
      c.show_commits(@client, @config, @deep)
    end
    print "\n"
  end

  def show_forks
    c = Repositories.new
    if @deep == ORGS_REPO || @deep == USER_REPO || @deep == TEAM_REPO
      c.show_forks(@client, @config, @deep)
    end
  end

  def collaborators
    c = Repositories.new
    if @deep == ORGS_REPO || @deep == USER_REPO || @deep == TEAM_REPO
      c.show_collaborators(@client, @config, @deep)
    end
  end

  def add_command(command_name, command)
    @commands[command_name] = command
  end

  def run_command(command_name, params)
    @comands[command_name].call(params)
  end

  # Main program
  def run(config_path, argv_token, user)
    puts "los comandos: #{@commands}"
    ex = 1
    opscript = []
    @sysbh.write_initial_memory
    HelpM.new.welcome
    o = Organizations.new
    t = Teams.new
    r = Repositories.new
    s = Sys.new
    u = User.new
    # orden de búsqueda: ~/.ghedsh.json ./ghedsh.json ENV["ghedsh"] --configpath path/to/file.json

    # control de carga de parametros en el logueo de la aplicacion
    if !user.nil?
      @config = s.load_config_user(config_path, user)
      @client = s.client
      ex = 0 if @config.nil?
      @deep = USER
    else
      @config = s.load_config(config_path, argv_token) # retorna la configuracion ya guardada anteriormente
      @client = s.client
      @deep = s.return_deep(config_path)
      # if @deep==ORGS then @teamlist=t.get_teamlist end  #solucion a la carga de las ids de los equipos de trabajo
    end
    @sysbh.load_memory(config_path, @config)
    # @deep=USER
    unless @client.nil?
      @sysbh.add_history_str(2, Organizations.new.read_orgs(@client))
    end
    while ex != 0
      if opscript.empty?
        begin
          op = Readline.readline(prompt, true).strip
          # puts "op: #{op}"
          opcd = op.split
          # puts "opcd: #{opcd}"
          command = opcd[0]
          opcd.shift
          param = opcd
          puts "command: #{command}"
          puts "params: #{param.class}"
          unless command.to_s.empty?
            if !@commands.key?(command)
              puts 'no exite ese comando'
            else
              @commands[command].call(0) # params
            end
          end
        rescue StandardError
          puts
          throw :ctrl_c
          op = 'exit'; opcd = 'exit'
        end
      else
        op = opscript[0]
        opcd = op.split
        opscript.shift
      end

    end
  end
end
