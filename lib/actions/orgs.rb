require 'json'
require 'csv'
require 'fileutils'
require 'require_all'
require_relative '../common'
require_relative '../helpers'

GITHUB_LIST = %w[githubid github idgithub github_id id_github githubuser github_user].freeze
MAIL_LIST = ['email', 'mail', 'e-mail'].freeze

# @see http://octokit.github.io/octokit.rb/Octokit/Client.html
class Organization
  def self.shell_prompt(config)
    if config['Repo'].nil?
      Rainbow("#{config['User']}> ").aqua << Rainbow("#{config['Org']}> ").magenta
    else
      Rainbow("#{config['User']}> ").aqua << Rainbow("#{config['Org']}> ").magenta << Rainbow("#{config['Repo']}> ").color(236, 151, 21)
    end
  end

  def build_cd_syntax(type, name)
    syntax_map = { 'repo' => "Organization.new.cd('repo', #{name}, client, env)",
                   'team' => "Organization.new.cd('team', #{name}, client, env)" }
    unless syntax_map.key?(type)
      raise Rainbow("cd #{type} currently not supported.").color(ERROR_CODE)
    end
    syntax_map[type]
  end

  def open_info(config, params, client)
    unless params.nil?
      # looking for org member by regexp
      pattern = build_regexp_from_string(params)
      member_url = select_member(config, pattern, client)
      open_url(member_url.to_s) unless member_url.nil?
      return
    end

    if config['Repo'].nil?
      open_url(config['org_url'].to_s)
    else
      open_url(config['repo_url'].to_s)
    end
  rescue StandardError => exception
    puts Rainbow(exception.message.to_s).color(ERROR_CODE)
    puts
  end

  def show_repos(client, config, params)
    spinner = custom_spinner("Fetching #{config['Org']} repositories :spinner ...")
    spinner.auto_spin
    org_repos = []
    client.organization_repositories(config['Org'].to_s).each do |repo|
      org_repos << repo[:name]
    end
    spinner.stop(Rainbow('done!').color(4, 255, 0))
    if params.nil?
      org_repos.each do |repo_name|
        puts repo_name
      end
    else
      pattern = build_regexp_from_string(params)
      occurrences = show_matching_items(org_repos, pattern)
      puts Rainbow("No repository inside #{config['Org']} matched  \/#{pattern.source}\/").color(INFO_CODE) if occurrences.zero?
    end
  end

  def show_teams(client, config, params)
    org_teams = []
    spinner = custom_spinner("Fetching #{config['Org']} teams :spinner ...")
    spinner.auto_spin
    client.organization_teams(config['Org'].to_s).each do |team|
      org_teams << team[:name]
    end
    spinner.stop(Rainbow('done!').color(4, 255, 0))
    if params.nil?
      org_teams.each do |name|
        puts name
      end
    else
      pattern = build_regexp_from_string(params)
      occurrences = show_matching_items(org_teams, pattern)
      puts Rainbow("No team inside #{config['Org']} matched  \/#{pattern.source}\/").color(INFO_CODE) if occurrences.zero?
    end
  end

  def clone_repository(client, repo_name, custom_path)
    ssh_url = []
    if repo_name.include?('/')
      pattern = build_regexp_from_string(repo_name)
      client.organization_repositories(config['Org'].to_s).each do |repo|
        ssh_url << repo[:clone_url] if pattern.match(repo[:name])
      end
      puts Rainbow("No repository matched \/#{pattern.source}\/").color(INFO_CODE) if ssh_url.empty?
    else
      repo = client.repository("#{config['Org']}/#{repo_name}")
      ssh_url << repo[:ssh_url]
    end
    unless ssh_url.empty?
      perform_git_clone(ssh_url, custom_path)
      if custom_path.nil?
        puts Rainbow("Cloned files are on directory #{Dir.home}/ghedsh_cloned").color(INFO_CODE)
      else
        puts Rainbow("Cloned files are on directory #{Dir.home}#{custom_path}").color(INFO_CODE)
      end
      puts
    end
  rescue StandardError => exception
    puts Rainbow(exception.message.to_s).color(ERROR_CODE)
    puts
  end

  def show_people(client, config, params)
    spinner = custom_spinner("Fetching #{config['Org']} people :spinner ...")
    spinner.auto_spin
    org_members = []
    client.organization_members(config['Org'].to_s).each do |member|
      org_members << [member[:login], 'member']
    end
    membership = {}
    client.organization_membership(config['Org'].to_s).each do |key, value|
      membership[key] = value
    end
    if membership[:role] == 'admin'
      client.outside_collaborators(config['Org'].to_s).each do |collab|
        org_members << [collab[:login], 'outside collaborator']
      end
    end
    spinner.stop(Rainbow('done!').color(4, 255, 0))
    if params.nil?
      table = Terminal::Table.new headings: ['Github ID', 'Role'], rows: org_members
      puts table
    else
      pattern = build_regexp_from_string(params)
      occurrences = build_item_table(org_members, pattern) # show_matching_items(org_members, pattern)
      puts Rainbow("No member inside #{config['Org']} matched  \/#{pattern.source}\/").color(INFO_CODE) if occurrences.zero?
    end
  end

  def cd_repo(name, client, enviroment)
    if name.class == Regexp
      pattern = Regexp.new(name.source, name.options)
      org_repos = []
      org_repos_url = {}
      spinner = custom_spinner("Matching #{enviroment.config['Org']} repositories :spinner ...")
      spinner.auto_spin
      client.organization_repositories(enviroment.config['Org'].to_s).each do |org_repo|
        if pattern.match(org_repo[:name].to_s)
          org_repos << org_repo[:name]
          org_repos_url[org_repo[:name].to_s] = org_repo[:html_url]
        end
      end
      spinner.stop(Rainbow('done!').color(4, 255, 0))
      if org_repos.empty?
        puts Rainbow("No repository matched with #{name.source} inside organization #{enviroment.config['Org']}").color(WARNING_CODE)
        puts
        return
      else
        prompt = TTY::Prompt.new
        answer = prompt.select('Select desired organization repository', org_repos)
        enviroment.config['Repo'] = answer
        enviroment.config['repo_url'] = org_repos_url[answer]
        enviroment.deep = Organization
      end
    else
      if client.repository?("#{enviroment.config['Org']}/#{name}")
        org_repo_url = 'https://github.com/' << enviroment.config['Org'].to_s << '/' << name.to_s
        enviroment.config['Repo'] = name
        enviroment.config['repo_url'] = org_repo_url
        enviroment.deep = Organization
      else
        puts Rainbow("Maybe #{name} is not an organizaton or currently does not exist.").color(WARNING_CODE)
        return
      end
    end
    enviroment
  end

  def cd_team(name, client, enviroment)
    org_teams = []
    org_teams_id = {}
    spinner = custom_spinner("Fetching #{enviroment.config['Org']} teams :spinner ...")
    spinner.auto_spin
    client.organization_teams(enviroment.config['Org'].to_s).each do |team|
      org_teams << team[:name]
      org_teams_id[team[:name].to_s] = team[:id]
    end
    spinner.stop(Rainbow('done!').color(4, 255, 0))
    if name.class == Regexp
      pattern = Regexp.new(name.source, name.options)
      name_matches = []
      org_teams.each do |team_name|
        name_matches << team_name if pattern.match(team_name.to_s)
      end
      if name_matches.empty?
        puts Rainbow("No team matched with \/#{name.source}\/ inside organization #{enviroment.config['Org']}").color(WARNING_CODE)
        puts
        return
      else
        prompt = TTY::Prompt.new
        answer = prompt.select('Select desired organization', name_matches)
        enviroment.config['Team'] = answer
        enviroment.config['TeamID'] = org_teams_id[answer]
        enviroment.config['team_url'] = 'https://github.com/orgs/' << enviroment.config['Org'] << '/teams/' << enviroment.config['Team']
        enviroment.deep = Team
      end
    else
      if org_teams.include?(name)
        enviroment.config['Team'] = name
        enviroment.config['TeamID'] = org_teams_id[name]
        enviroment.config['team_url'] = 'https://github.com/orgs/' << enviroment.config['Org'] << '/teams/' << enviroment.config['Team']
        enviroment.deep = Team
      else
        puts Rainbow("Maybe #{name} is not a #{enviroment.config['Org']} team or currently does not exist.").color(WARNING_CODE)
        puts
        return
      end
    end
    enviroment
  end

  # cd method contains a hash representing where user can navigate depending on context. In this case
  # inside an organization user is allowed to change to a org repo and org team.
  # In order to add new 'cd types' see example below.
  # @params type [String] name of the navigating option (repo, org, team, etc.)
  # @params name [String|Regexp] String or Regexp to find the repository.
  def cd(type, name, client, enviroment)
    cd_scopes = { 'repo' => method(:cd_repo), 'team' => method(:cd_team) }
    cd_scopes[type].call(name, client, enviroment)
  end

  # Shows commits of current repo. If user is not in a repo, repository name for commit showing must be provided.
  # @params enviroment [ShellContext] contains the shell context, including Octokit client and user config
  # @params params [Array<String>] if user is not on a repo then params[0] is repo name. Optionally,
  #   branch can be specified (value is in params[1]), if not provided default branch is master
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
      enviroment.client.commits("#{enviroment.config['Org']}/#{repo}", options).each do |i|
        puts "\tSHA: #{i[:sha]}"
        puts "\t\t Commit date: #{i[:commit][:author][:date]}"
        puts "\t\t Commit author: #{i[:commit][:author][:name]}"
        puts "\t\t\t Commit message: #{i[:commit][:message]}"
        puts
      end
    rescue StandardError => exception
      puts exception
      puts Rainbow("If you are not currently on a repo, USAGE TIP: `commits <repo_name> [branch_name]` (default: 'master')").color(INFO_CODE)
    end
  end

  # Repo creation: creates new repo inside current org
  # @param enviroment [ShellContext] contains the shell context, including Octokit client and user config
  # @param repo_name [String] repository name
  # @param options [Hash] repository options (repo organization, visibility, etc)
  def create_repo(enviroment, repo_name, options)
    client = enviroment.client
    options[:organization] = enviroment.config['Org'].to_s
    client.create_repository(repo_name, options)
    puts Rainbow('Repository created correctly!').color(79, 138, 16)
 rescue StandardError => exception
   puts Rainbow(exception.message.to_s).color(ERROR_CODE)
   puts
 end

  # Removes repository by name
  # @param enviroment [ShellContext] contains the shell context, including Octokit client and user config
  # @param repo_name [String] name of the repo to be removed

  def remove_repo(enviroment, repo_name)
    client = enviroment.client
    client.delete_repository("#{enviroment.config['Org']}/#{repo_name}")
    puts Rainbow('Repository deleted.').color(INFO_CODE)
  rescue StandardError => exception
    puts Rainbow(exception.message.to_s).color(ERROR_CODE)
    puts
  end

  # Team creation: opens team creation page on default browser when calling new_team
  # with no options. If option provided, it must be the directory and name of the JSON file
  # somewhere in your HOME directory for bulk creation of teams and members.
  # @param client [Object] Octokit client object
  # @param config [Hash] user configuration tracking current org, repo, etc.
  # @param params [Array<String>] user specified parameters, if not nil must be path to teams JSON file.
  # @example Open current org and create new team
  #   User > Org > new_team
  # @example Create multiple teams with its members inside current org
  #   User > Org > new_team HOME/path/to/file/creation.json
  def create_team(client, config, params)
    if params.nil?
      team_creation_url = "https://github.com/orgs/#{config['Org']}/new-team"
      open_url(team_creation_url)
    else
      members_not_added = []
      begin
        file_path = "#{Dir.home}#{params}"
        teams_json = File.read(file_path)
        teams_file = JSON.parse(teams_json)
        spinner = custom_spinner("Creating teams in #{config['Orgs']} :spinner ...")
        teams_file['teams'].each do |team|
          # assigned to 'created_team' to grab the ID (and use it for adding members)
          # of the newly created team
          created_team = client.create_team(config['Org'].to_s,
                                            name: team['name'].to_s,
                                            privacy: team['privacy'])
          team['members'].each do |member|
            member_addition = client.add_team_member(created_team[:id], member)
            members_not_added.push(member) if member_addition == false # if !!member_adition
          end
        end
        spinner.stop(Rainbow('done!').color(4, 255, 0))
        puts Rainbow('Teams created correctly!').color(79, 138, 16)
        puts Rainbow("Could not add following members: #{members_not_added}").color(WARNING_CODE) unless members_not_added.empty?
      rescue StandardError => e
        puts e.message
      end
    end
  end

  def search_rexp_people_info(_client, config, exp)
    list = load_people
    if !list.nil?
      if list['users'] != []
        list = list['orgs'].detect { |aux| aux['name'] == config['Org'] }
        if exp =~ /^\//
          sp = exp.split('/')
          exp = Regexp.new(sp[1], sp[2])
        end
        list = Sys.new.search_rexp_peoplehash(list['users'], exp)

        if list != []
          fields = list[0].keys
          list.each do |i|
            puts "\n\e[31m#{i['github']}\e[0m"
            fields.each do |j|
              puts "#{j.capitalize}:\t #{i[j]}"
            end
            puts
          end
        end
      else
        puts 'Extended information has not been added yet'
      end
    else
      list['orgs'].push('name' => config['Org'], 'users' => [])
      Sys.new.save_people("#{ENV['HOME']}/.ghedsh", list)
      puts 'Extended information has not been added yet'
    end
  end

  def show_organization_members_bs(client, config)
    orgslist = []
    print "\n"
    mem = client.organization_members(config['Org'])
    mem.each do |i|
      m = eval(i.inspect)
      orgslist.push(m[:login])
      puts m[:login]
    end
    puts
    orgslist
  end

  def get_organization_members(client, config)
    mem = client.organization_members(config['Org'])
    list = []
    unless mem.nil?
      mem.each do |i|
        list << i[:login]
      end
    end
    list
  end

  def read_orgs(client)
    orgslist = []
    org = client.organizations
    org.each do |i|
      o = eval(i.inspect)
      orgslist.push(o[:login])
    end
    orgslist
  end

  def open_org(client, config)
    mem = client.organization(config['Org'])
    Sys.new.open_url(mem[:html_url])
  end
end
