require 'require_all'
require 'json'
require 'readline'
require 'octokit'
require 'optparse'
require 'version'
require 'context'
require 'artii'
require 'rainbow'

class Interface
  def initialize; end

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
          @shell_enviroment = ShellContext.new(options[:user], options[:path], options[:token])
        else
          @shell_enviroment = ShellContext.new(options[:user], "#{ENV['HOME']}/.ghedsh", options[:token])
        end
        run
      rescue SystemExit, Interrupt
        raise
      rescue Exception => e
        puts 'exit'
        puts e
      end
    end
  end

  # Main program
  def run
    a = Artii::Base.new
    puts Rainbow(a.asciify('GitHub Education Shell')).color(98, 177, 124)
    loop do
      begin
        input = Readline.readline(@shell_enviroment.prompt, true).strip.split
        command = input[0]
        input.shift
        command_params = input
        unless command.to_s.empty?
          if !@shell_enviroment.commands.key?(command)
            puts "#{command}: command not found"
          else
            result = @shell_enviroment.commands[command].call(command_params)
          end
        end
      rescue StandardError => e
        puts e
        # puts
        # throw :ctrl_c
      end
      break if result == 0
    end
  end
end
