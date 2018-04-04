require 'version'
require 'common'
require 'ostruct'
require 'net/http'
require 'json'

class Commands
  attr_reader   :enviroment
  attr_accessor :struct

  def initialize
    @context_stack = []
    add_command('clear', method(:clear))
    # add_command('help', method(:help))
    add_command('exit', method(:exit))
    add_command('new_repo', method(:new_repo))
    add_command('commits', method(:display_commits))
    add_command('orgs', method(:orgs))
    add_command('orgsn', method(:orgsn))
    add_command('cd', method(:change_context))
    add_command('get', method(:get))
    add_command('bash', method(:bash))
  end

  def add_command(command_name, command)
    COMMANDS[command_name] = command
  end

  def load_enviroment(console_enviroment)
    @enviroment = console_enviroment
    @struct = OpenStruct.new
    default_enviroment = { 'User' => @enviroment.client.login.to_s, 'Org' => nil, 'Repo' => nil, 'Team' => nil, 'TeamID' => nil, 'Assig' => nil }
    @struct.config = default_enviroment
    @struct.deep = User
    @context_stack.push(@struct)
  end

  #   def help(opcd)
  #     h = HelpM.new
  #     if opcd.size >= 1
  #       h.context(opcd[0..opcd.size - 1], @enviroment.deep)
  #     else
  #       if @enviroment.deep == USER
  #         h.user
  #       elsif @enviroment.deep == ORG
  #         h.org
  #       elsif @enviroment.deep == ORGS_REPO
  #         h.org_repo
  #       elsif @enviroment.deep == USER_REPO
  #         h.user_repo
  #       elsif @enviroment.deep == TEAM
  #         h.orgs_teams
  #       elsif @enviroment.deep == TEAM_REPO
  #         h.team_repo
  #       elsif @enviroment.deep == ASSIG
  #         h.asssig
  #       end
  #     end
  #   rescue StandardError => exception
  #     puts exception
  #   end
  def orgs(_params)
    if @enviroment.deep.method_defined? :show_organizations
      @enviroment.deep.new.show_organizations(@enviroment.client)
    else
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").indianred
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
    # prueba-clasroom
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

  def open(params); end

  def new_repo(_params)
   

    # user_url = @enviroment.client.web_endpoint << @enviroment.client.login
    # system("open #{user_url}")
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
      puts Rainbow("Command not available in context \"#{@enviroment.deep.name}\"").indianred
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

  # ejemplo cambio de contexto (cd): cd User.new.cd('org',/ULL-*/,client,env)
  def change_context(params)
    if params.empty?
      @enviroment.config['Org'] = nil
      @enviroment.config['Repo'] = nil
      @enviroment.config['Team'] = nil
      @enviroment.config['TeamID'] = nil
      @enviroment.config['Assig'] = nil

      @context_stack.clear
      @context_stack.push(@struct)

      @enviroment.deep = User
    elsif params[0] == '..'
      if @context_stack.size > 1
        @context_stack.pop
        stack_pointer = @context_stack.last

        @enviroment.config = stack_pointer.config
        @enviroment.deep = stack_pointer.deep
      else
        @enviroment.config = @struct.config
        @enviroment.deep = @struct.deep
      end
    else
      begin
        action = params.join('')
        env = OpenStruct.new
        env.config = Marshal.load(Marshal.dump(@enviroment.config))
        env.deep = @enviroment.deep
        client = @enviroment.client
        action.chomp!(')')
        action << ', client, env)'
        ret = eval(action)
        unless ret.nil?
          current_enviroment = OpenStruct.new
          current_enviroment.config = ret.config
          current_enviroment.deep = ret.deep
          @context_stack.push(current_enviroment)
          @enviroment.config = ret.config
          @enviroment.deep = ret.deep
        end
        # manejar syntax error para añadir sugerencia
      rescue StandardError => exception
        puts Rainbow(exception.message).indianred
      rescue SyntaxError => err
        puts Rainbow('Syntax Error typing the command. Tip: cd <class>.new.cd(<scope>, <name or /Regexp>/)').indianred
      end
    end
  end
end
