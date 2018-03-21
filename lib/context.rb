require 'common'
require 'version'
require 'commands'

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
      @sysbh.add_history_str(2, Organization.new.read_orgs(@client))
    end

    # let commands class access context variables
    share_context = Commands.new
    share_context.load_enviroment(self)
    @commands = COMMANDS
  end
  
  def prompt
    @deep.shell_prompt(@config, @repo_path)
  end
end
