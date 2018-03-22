require 'readline'
require 'octokit'
require 'json'
require 'require_all'
require_rel '.'
require 'tty-prompt'

class User
  def info(client)
    mem = client.user(client.login)
    puts m[:login]
    puts m[:name]
    puts m[:email]
  end

  def self.cd(type, name, enviroment)
    case type
    when 'org'
      if name.class == Regexp
        pattern = Regexp.new(name.source)
        user_orgs = []
        enviroment.client.organizations.each do |org|
          user_orgs << org[:login] if pattern.match((org[:login]).to_s)
        end
        if user_orgs.empty?
          puts "No repo match with #{name}"
        else
          prompt = TTY::Prompt.new
          prompt.on(:keypress) do |event|
            prompt.trigger(:keydown) if event.value == 'j'
            prompt.trigger(:keyup) if event.value == 'k'
          end
          answer = prompt.select('Select desired repo', user_orgs)
          if enviroment.client.organization_member?(answer.to_s, enviroment.client.login.to_s)
            enviroment.config['Org'] = answer
            enviroment.deep = Organization
          end
        end
      else
        if enviroment.client.organization_member?(name.to_s, enviroment.client.login.to_s)
          enviroment.config['Org'] = name
          enviroment.deep = Organization
        else
          puts "You are not currently #{name} member or #{name} is not an Organization."
        end
      end
    else
      puts 'nada'
    end
    enviroment
  end

  # Defined as method class in order to call it within context.rb
  def self.shell_prompt(config, _repo_path)
    if config['Repo'].nil?
      Rainbow("#{config['User']}> ").aqua
    else
      Rainbow("#{config['User']}> ").aqua + Rainbow("#{config['Repo']}> ").color(236, 151, 21)
    end
  end

  def open_user(client)
    mem = client.user(client.login)
    Sys.new.open_url(mem[:html_url])
  end

  def show_organizations(client, _config)
    puts
    organizations = client.list_organizations
    organizations.each do |i|
      puts i[:login]
    end
  end

  def show_commits(enviroment, params)
    options = {}
    if !enviroment.config['Repo'].nil?
      repo = enviroment.config['Repo']
      options[:sha] = if params.empty?
                        'master'
                      else
                        params[0]
                      end
    else
      repo = params[0]
      options[:sha] = if params[1].nil?
                        'master'
                      else
                        params[1]
                      end
    end

    begin
      mem = enviroment.client.commits("#{enviroment.config['User']}/#{repo}", options)
      mem.each do |i|
        puts "\tSHA: #{i[:sha]}"
        puts "\t\t Commit date: #{i[:commit][:author][:date]}"
        puts "\t\t Commit author: #{i[:commit][:author][:name]}"
        puts "\t\t\t Commit message: #{i[:commit][:message]}"
      end
    rescue StandardError => exception
      puts exception
      puts "If you are not currently on a repo, USAGE TIP: `commits <repo_name> [branch_name]` (default: 'master')"
    end
  end
end
