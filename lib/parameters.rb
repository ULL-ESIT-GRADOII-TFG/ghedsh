require 'actions/help'
require 'actions/orgs'
require 'actions/repo'
require 'actions/system'
require 'actions/teams'
require 'actions/user'
require 'version'
require 'commands'

# USER = 1
# ORGS = 2
# USER_REPO = 10
# ORGS_REPO = 3
# TEAM = 4
# ASSIG = 6
# TEAM_REPO = 5

class ShellContext
  attr_accessor :deep
  attr_accessor :config
  attr_accessor :client
  attr_accessor :sysbh
  attr_accessor :repo_path
  attr_accessor :commands
  attr_accessor :config_path

  def initialize(user, config_path, argv_token)
    @repo_path = ''
    @commands = {}
    @config_path = config_path
    @sysbh = Sys.new
    @sysbh.write_initial_memory
    # orden de busqueda: ~/.ghedsh.json ./ghedsh.json ENV["ghedsh"] --configpath path/to/file.json

    # control de carga de parametros en el logueo de la aplicacion
    if !user.nil?
      @config = @sysbh.load_config_user(config_path, user)
      @client = @sysbh.client
      ex = 0 if @config.nil? # !!!!!!!!!!!!!!! revisar 'ex', no pertenece aqui
      @deep = USER
    else
      @config = @sysbh.load_config(config_path, argv_token) # retorna la configuracion ya guardada anteriormente
      @client = @sysbh.client
      @deep = @sysbh.return_deep(config_path)
    end
    @sysbh.load_memory(config_path, @config)
    unless @client.nil?
      @sysbh.add_history_str(2, Organizations.new.read_orgs(@client))
    end

    # let commands class access context variables
    share_context = Commands.new
    share_context.load_enviroment(self)
    add_command('clear', share_context.method(:clear))
    add_command('repos', share_context.method(:repos))
    add_command('help', share_context.method(:help))
    add_command('exit', share_context.method(:exit))
  end

  def add_command(command_name, command)
    @commands[command_name] = command
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
end
