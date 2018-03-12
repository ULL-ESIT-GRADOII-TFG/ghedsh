require 'readline'
require 'octokit'
require 'json'
require 'require_all'
require_rel '.'

class User
  def info(client)
    mem=client.user(client.login)
    puts m[:login]
    puts m[:name]
    puts m[:email]
  end

  def open_user(client)
    mem=client.user(client.login)
    Sys.new.open_url(mem[:html_url])
  end

  def show_commits(enviroment, params)
    options = {}
    repo = enviroment.config["Repo"] || params[0]
    unless params.empty?
      options[:sha] = params[1]
      puts "me asigno en parametros: #{options[:sha]}"
    else
      options[:sha] = "master"
      puts "me asigno en default: #{options[:sha]}"
    end
    mem=enviroment.client.commits("#{enviroment.config["User"]}/pagina-irene",options)
    mem.each  do |i|
        puts "\tSHA: #{i[:sha]}"
        puts "\t\t Commit date: #{i[:commit][:author][:date]}"
        puts "\t\t Commit author: #{i[:commit][:author][:name]}"
        puts "\t\t\t Commit message: #{i[:commit][:message]}"
    end
  end
end
