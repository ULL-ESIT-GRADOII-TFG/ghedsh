require 'require_all'
require_rel '.'
require_relative '../common'
require_relative '../helpers'
require 'ostruct'

class User
  # Defined as method class in order to call it within context.rb
  def self.shell_prompt(config)
    if config['Repo'].nil?
      Rainbow("#{config['User']}> ").aqua
    else
      Rainbow("#{config['User']}> ").aqua + Rainbow("#{config['Repo']}> ").color(236, 151, 21)
    end
  end

  def build_cd_syntax(type, name)
    syntax_map = { 'repo' => "User.new.cd('repo', #{name}, client, env)",
                   'org' => "User.new.cd('org', #{name}, client, env)" }
    unless syntax_map.key?(type)
      raise Rainbow("cd #{type} currently not supported.").color(ERROR_CODE)
    end
    syntax_map[type]
  end

  def open_info(config, _params = nil, _client = nil)
    if config['Repo'].nil?
      open_url(config['user_url'].to_s)
    else
      open_url(config['repo_url'].to_s)
    end
  end

  def cd_org(name, client, enviroment)
    if name.class == Regexp
      pattern = Regexp.new(name.source, name.options)
      user_orgs = []
      user_orgs_url = {}
      spinner = custom_spinner("Matching #{client.login} organizations :spinner ...")
      spinner.auto_spin
      client.organizations.each do |org|
        if pattern.match((org[:login]).to_s)
          user_orgs << org[:login]
          user_orgs_url[org[:login].to_s] = 'https://github.com/' << org[:login].to_s
        end
      end
      spinner.stop(Rainbow('done!').color(4, 255, 0))
      if user_orgs.empty?
        puts Rainbow("No organization match with #{name.source}").color(WARNING_CODE)
        puts
        return
      else
        prompt = TTY::Prompt.new
        answer = prompt.select('Select desired organization', user_orgs)
        enviroment.config['Org'] = answer
        enviroment.config['org_url'] = user_orgs_url[answer]
        enviroment.deep = Organization
      end
    else
      if client.organization_member?(name.to_s, client.login.to_s)
        enviroment.config['Org'] = name
        enviroment.config['org_url'] = 'https://github.com/' << name.to_s
        enviroment.deep = Organization
      else
        puts Rainbow("You are not currently #{name} member or #{name} is not an Organization.").color(WARNING_CODE)
        puts
        return
      end
    end
    enviroment
  end

  def cd_repo(name, client, enviroment)
    if name.class == Regexp
      pattern = Regexp.new(name.source, name.options)
      user_repos = []
      user_repos_url = {}
      spinner = custom_spinner("Matching #{client.login} repositories :spinner ...")
      spinner.auto_spin
      client.repositories.each do |repo|
        if pattern.match(repo[:name].to_s)
          user_repos << repo[:name]
          user_repos_url[repo[:name].to_s] = repo[:html_url]
        end
      end
      spinner.stop(Rainbow('done!').color(4, 255, 0))
      if user_repos.empty?
        puts Rainbow("No repository match with \/#{name.source}\/").color(WARNING_CODE)
        return
      else
        prompt = TTY::Prompt.new
        answer = prompt.select('Select desired repository', user_repos)
        enviroment.config['Repo'] = answer
        enviroment.config['repo_url'] = user_repos_url[answer]
        enviroment.deep = User
      end
    else
      if client.repository?("#{client.login}/#{name}")
        res = {}
        # client.repository returns array of arrays (in hash format)[ [key1, value1], [key2, value2] ]
        # thats why first we convert the api response to hash
        client.repository("#{client.login}/#{name}").each do |key, value|
          res[key] = value
        end
        enviroment.config['Repo'] = name
        enviroment.config['repo_url'] = res[:html_url]
        enviroment.deep = User
      else
        puts Rainbow("Maybe #{name} is not a repository or currently does not exist.").color(WARNING_CODE)
        return
      end
    end
    enviroment
  end

  def cd(type, name, client, enviroment)
    cd_scopes = { 'org' => method(:cd_org), 'repo' => method(:cd_repo) }
    cd_scopes[type].call(name, client, enviroment)
  end

  def show_repos(client, _config, params)
    spinner = custom_spinner("Fetching #{client.login} repositories :spinner ...")
    spinner.auto_spin
    user_repos = []
    client.repositories.each do |repo|
      user_repos << repo[:name]
    end
    user_repos.sort_by!(&:downcase)
    spinner.stop(Rainbow('done!').color(4, 255, 0))
    if params.nil?
      item_counter = 0
      user_repos.each do |repo_name|
        puts repo_name
        item_counter += 1
      end
      puts "\n#{item_counter} user repositories listed."
    else
      pattern = build_regexp_from_string(params)
      occurrences = show_matching_items(user_repos, pattern)
      puts Rainbow("No repository matched \/#{pattern.source}\/").color(INFO_CODE) if occurrences.zero?
      puts "\n#{occurrences} user repositories listed."
    end
  end

  def change_to_private_repo(client, _config, params)
    pattern = build_regexp_from_string(params)
    spinner = custom_spinner('Setting private repos :spinner ...')
    spinner.auto_spin
    repos = []
    client.repositories.each do |repo|
      repos.push(repo[:name]) if pattern.match(repo[:name])
    end
    repos.each do |i|
      client.set_private("#{client.login}/#{i}")
    end
    spinner.stop(Rainbow('done!').color(4, 255, 0))
  rescue StandardError => exception
    puts Rainbow(exception.message.to_s).color(ERROR_CODE)
  end

  def change_to_public_repo(client, _config, params)
    pattern = build_regexp_from_string(params)
    spinner = custom_spinner('Setting public repos :spinner ...')
    spinner.auto_spin
    repos = []
    client.repositories.each do |repo|
      repos.push(repo[:name]) if pattern.match(repo[:name])
    end
    repos.each do |i|
      client.set_public("#{client.login}/#{i}")
    end
    spinner.stop(Rainbow('done!').color(4, 255, 0))
  rescue StandardError => exception
    puts Rainbow(exception.message.to_s).color(ERROR_CODE)
  end

  def show_organizations(client, params)
    spinner = custom_spinner("Fetching #{client.login} organizations :spinner ...")
    spinner.auto_spin
    user_orgs = []
    client.list_organizations.each do |org|
      user_orgs << org[:login]
    end
    user_orgs.sort_by!(&:downcase)
    spinner.stop(Rainbow('done!').color(4, 255, 0))
    if params.empty?
      user_orgs.each do |org_name|
        puts org_name
      end
    else
      pattern = build_regexp_from_string(params[0])
      occurrences = show_matching_items(user_orgs, pattern)
      puts Rainbow("No organization matched \/#{pattern.source}\/").color(INFO_CODE) if occurrences.zero?
    end
  end

  def create_repo(enviroment, repo_name, options)
    client = enviroment.client
    client.create_repository(repo_name, options)
    puts Rainbow('Repository created correctly!').color(79, 138, 16)
  rescue StandardError => exception
    puts Rainbow(exception.message.to_s).color(ERROR_CODE)
    puts
  end

  def remove_repo(enviroment, repo_name)
    client = enviroment.client
    client.delete_repository("#{client.login}/#{repo_name}")
    puts Rainbow('Repository deleted.').color(INFO_CODE)
  rescue StandardError => exception
    puts
    puts Rainbow(exception.message.to_s).color('#cc0000')
  end

  def create_issue(config)
    if config['Repo']
      issue_creation_url = "https://github.com/#{config['User']}/#{config['Repo']}/issues/new"
      open_url(issue_creation_url)
    else
      puts Rainbow('Change to repo in order to create an issue.').color(INFO_CODE)
    end
  end

  def show_issues(config)
    if config['Repo']
      issues_url = "https://github.com/#{config['User']}/#{config['Repo']}/issues"
      open_url(issues_url)
    else
      puts Rainbow('Change to repo in order to view all issues').color(INFO_CODE)
    end
  end

  def show_files(client, config, params)
    if config['Repo']
      options = { path: '' }
      options[:path] = params[0] unless params.empty?
      file_names_and_types = []
      client.contents("#{client.login}/#{config['Repo']}", options).each do |i|
        file_names_and_types << "#{i[:name]} (#{i[:type]})"
      end
      file_names_and_types.sort_by!(&:downcase)
      puts file_names_and_types
    else
      puts Rainbow('Please change to repository to see its files.').color(INFO_CODE)
    end
  rescue StandardError => e
    puts Rainbow(e.message.to_s).color(ERROR_CODE)
  end

  def clone_repository(enviroment, repo_name, custom_path)
    client = enviroment.client
    repos_to_clone = []
    if repo_name.include?('/')
      pattern = build_regexp_from_string(repo_name)
      client.repositories.each do |repo|
        repos_to_clone << { name: repo[:name], ssh_url: repo[:clone_url] } if pattern.match(repo[:name])
      end
      puts Rainbow("No repository matched \/#{pattern.source}\/").color(INFO_CODE) if repos_to_clone.empty?
    else
      repo = client.repository("#{client.login}/#{repo_name}")
      repos_to_clone << { name: repo[:name], ssh_url: repo[:clone_url] }
    end
    unless repos_to_clone.empty?
      perform_git_clone(repos_to_clone, custom_path)
      if custom_path.nil?
        puts Rainbow("Cloned into #{Dir.pwd}").color(INFO_CODE).underline
      else
        puts Rainbow("Cloned into #{Dir.home}#{custom_path}").color(INFO_CODE).underline
      end
      puts
    end
  rescue StandardError => exception
    puts Rainbow(exception.message.to_s).color('#cc0000')
    puts
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
      puts Rainbow("If you are not currently on a repo, USAGE TIP: `commits <repo_name> [branch_name]` (default: 'master')").color(INFO_CODE)
      puts
    end
  end
end
