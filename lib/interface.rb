require 'require_all'
require 'json'
require 'readline'
require 'octokit'
require 'optparse'
require 'version'
require 'parameters'

class Interface
  # attr_accessor :commands

  def initialize
    # @repos_list = []; @orgs_repos = []; @teams_repos = []; @orgs_list = []; @teamlist = []
    # @repo_path = ''
    # @commands = {}
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

  # Main program
  def run(config_path, argv_token, user)
    opscript = []
    shell_enviroment = ShellContext.new(user, config_path, argv_token)
    puts "los comandos: #{shell_enviroment.commands}"
    HelpM.new.welcome
    loop do
      if opscript.empty?
        begin
          op = Readline.readline(shell_enviroment.prompt, true).strip
          # puts "op: #{op}"
          opcd = op.split
          # puts "opcd: #{opcd}"
          command = opcd[0]
          opcd.shift
          command_params = opcd
          puts "command: #{command}"
          # puts "params: #{command_params}"
          unless command.to_s.empty?
            if !shell_enviroment.commands.key?(command)
              puts 'no exite ese comando'
            else
              result = shell_enviroment.commands[command].call(command_params)
            end
          end
        rescue StandardError
          # puts
          # throw :ctrl_c
          op = 'exit'; opcd = 'exit'
        end
      else
        op = opscript[0]
        opcd = op.split
        opscript.shift
      end
      break if result == 0
    end
  end
end
