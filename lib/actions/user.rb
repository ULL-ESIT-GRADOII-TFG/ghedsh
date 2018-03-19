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

  def self.shell_prompt(config, repo_path)
    Rainbow(config['User'] + '> ').aqua
    
    #config['User'] + '> '
      #if repo_path != ''
        #config['User'] + '>' + "\e[31m#{config['Repo']}\e[0m" + '>' + repo_path.to_s + '> '
      #else
        #config['User'] + '>' + "\e[31m#{config['Repo']}\e[0m" + '> '
      #end
  end

  def open_user(client)
    mem=client.user(client.login)
    Sys.new.open_url(mem[:html_url])
  end

  def show_organizations(client, config)
    puts
    organizations = client.list_organizations
    organizations.each do |i|
      puts i[:login]
    end
  end

  def show_commits(enviroment, params)
    options = {}
    repo = enviroment.config["Repo"] || params[0]
   
    if params.empty?
      options[:sha] = params[1]
    else
      options[:sha] = "master"
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
