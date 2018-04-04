require 'require_all'
require_rel '.'
require 'common'
require_relative '../helpers'
require 'ostruct'

class User
  def info(client)
    mem = client.user(client.login)
    puts m[:login]
    puts m[:name]
    puts m[:email]
  end

  # Defined as method class in order to call it within context.rb
  def self.shell_prompt(config)
    if config['Repo'].nil?
      Rainbow("#{config['User']}> ").aqua
    else
      Rainbow("#{config['User']}> ").aqua + Rainbow("#{config['Repo']}> ").color(236, 151, 21)
    end
  end

  def cd_org(name, client, enviroment)
    if name.class == Regexp
      pattern = Regexp.new(name.source)
      user_orgs = []
      spinner = custom_spinner("Matching #{client.login} organizations :spinner ...")
      spinner.auto_spin
      client.organizations.each do |org|
        user_orgs << org[:login] if pattern.match((org[:login]).to_s)
      end
      spinner.stop(Rainbow('done!').color(4, 255, 0))
      if user_orgs.empty?
        puts Rainbow("No organization match with #{name}").color('#9f6000')
        return nil
      else
        prompt = TTY::Prompt.new
        answer = prompt.select('Select desired organization', user_orgs)
        if client.organization_member?(answer.to_s, client.login.to_s)
          enviroment.config['Org'] = answer
          enviroment.deep = Organization
        end
      end
    else
      if enviroment.client.organization_member?(name.to_s, client.login.to_s)
        enviroment.config['Org'] = name
        enviroment.deep = Organization
      else
        puts Rainbow("You are not currently #{name} member or #{name} is not an Organization.").color('#9f6000')
        return nil
      end
    end
    enviroment
  end

  def cd_repo(name, client, enviroment)
    if name.class == Regexp
      pattern = Regexp.new(name.source)
      user_repos = []
      spinner = custom_spinner("Matching #{client.login} repositories :spinner ...")
      spinner.auto_spin
      client.repositories.each do |repo|
        user_repos << repo[:name] if pattern.match(repo[:name].to_s)
      end
      spinner.stop(Rainbow('done!').color(4, 255, 0))
      if user_repos.empty?
        puts Rainbow("No repository match with #{name}").color('#9f6000')
        return nil
      else
        prompt = TTY::Prompt.new
        answer = prompt.select('Select desired repository', user_repos)
        enviroment.config['Repo'] = answer
        enviroment.deep = User
      end
    else
      if client.repository?("#{client.login}/#{name}")
        enviroment.config['Repo'] = name
        enviroment.deep = User
      else
        puts Rainbow("Maybe #{name} is not a repository or currently does not exist.").color('#9f6000')
        return nil
      end
    end
    enviroment
  end

  def cd(type, name, client, enviroment)
    cd_scopes = { 'org' => method(:cd_org), 'repo' => method(:cd_repo) }
    cd_scopes[type].call(name, client, enviroment)
  end

  def open_user(client)
    mem = client.user(client.login)
    Sys.new.open_url(mem[:html_url])
  end

  def show_organizations(client)
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
      enviroment.client.commits("#{enviroment.client.login}/#{repo}", options).each do |i|
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
