require 'json'
require 'csv'
require 'fileutils'
require 'require_all'
require_relative '../common'
require_relative '../helpers'

GITHUB_LIST = %w[githubid github idgithub github_id id_github githubuser github_user].freeze
MAIL_LIST = ['email', 'mail', 'e-mail'].freeze

# Class containing actions available inside an organization
#
# @see http://octokit.github.io/octokit.rb/Octokit/Client/Organizations.html
class Organization
  # CLI prompt, info about the current (CLI) scope
  # @param config [Hash] user configuration tracking current org, repo, etc.
  def self.shell_prompt(config)
    if config['Repo'].nil?
      Rainbow("#{config['User']}> ").aqua << Rainbow("#{config['Org']}> ").magenta
    else
      Rainbow("#{config['User']}> ").aqua << Rainbow("#{config['Org']}> ").magenta << Rainbow("#{config['Repo']}> ").color(236, 151, 21)
    end
  end

  # Builds final cd syntax. Transforms user's CLI input to valid Ruby expression doing some parsing.
  # @param type [String] scope of cd command
  # @param name [String, Regexp] name of repo, org, team etc. inside current organization
  # @return syntax_map [String] Valid Ruby expression to perform eval.
  def build_cd_syntax(type, name)
    syntax_map = { 'repo' => "Organization.new.cd('repo', #{name}, client, env)",
                   'team' => "Organization.new.cd('team', #{name}, client, env)" }
    unless syntax_map.key?(type)
      raise Rainbow("cd #{type} currently not supported.").color(ERROR_CODE)
    end
    syntax_map[type]
  end

  # Open info on default browser.
  #
  # If 'params' is String or Regexp user selects referred organization members
  #
  # @param config [Hash] user configuration tracking current org, repo, etc.
  # @params [String, Regexp]
  # @param client [Object] Octokit client object
  # @example open user profile URL with String provided
  #   User > Org > open 'some_user'
  # @example open user URL with Regexp provided
  #   User > Org > open /pattern/
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

  # Display organization repos
  #
  # @param client [Object] Octokit client object
  # @param config [Hash] user configuration tracking current org, repo, etc.
  # @param params [Regexp] regexp to check repo name
  def show_repos(client, config, params)
    spinner = custom_spinner("Fetching #{config['Org']} repositories :spinner ...")
    spinner.auto_spin
    org_repos = []
    client.organization_repositories(config['Org'].to_s).each do |repo|
      org_repos << repo[:name]
    end
    org_repos.sort_by!(&:downcase)
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

  # Set organization repos privacy to private. You need a paid plan to set private repos inside an organization
  #
  # @param client [Object] Octokit client object
  # @param config [Hash] user configuration tracking current org, repo, etc.
  # @param params [Regexp] regexp to change privacy of matching repos.
  def change_to_private_repo(client, config, params)
    pattern = build_regexp_from_string(params)
    spinner = custom_spinner('Setting private repos :spinner ...')
    spinner.auto_spin
    repos = []
    client.organization_repositories(config['Org'].to_s).each do |repo|
      repos.push(repo[:name]) if pattern.match(repo[:name])
    end
    repos.each do |i|
      client.set_private("#{config['Org']}/#{i}")
    end
    spinner.stop(Rainbow('done!').color(4, 255, 0))
  rescue StandardError => exception
    puts Rainbow(exception.message.to_s).color(ERROR_CODE)
  end

  # Set organization repos privacy to public.
  #
  # @param client [Object] Octokit client object
  # @param config [Hash] user configuration tracking current org, repo, etc.
  # @param params [Regexp] regexp to change privacy of matching repos.
  def change_to_public_repo(client, config, params)
    pattern = build_regexp_from_string(params)
    spinner = custom_spinner('Setting public repos :spinner ...')
    spinner.auto_spin
    repos = []
    client.organization_repositories(config['Org'].to_s).each do |repo|
      repos.push(repo[:name]) if pattern.match(repo[:name])
    end
    repos.each do |i|
      client.set_public("#{config['Org']}/#{i}")
    end
    spinner.stop(Rainbow('done!').color(4, 255, 0))
  rescue StandardError => exception
    puts Rainbow(exception.message.to_s).color(ERROR_CODE)
  end

  # Create a 'super repo' containing assignment repositories as submodules
  #
  # @param [Object] client Octokit client object
  # @param [Hash] config user configuration tracking current org, repo, etc.
  # @param [Array<String>] params 'super repo's' name and Regexp to match submodules
  #   params[0] is the evaluation repository's name
  #   params[1] Regexp of submodules
  def new_eval(client, config, params)
    options = { private: true, organization: config['Org'].to_s }
    repo_name = params[0]
    submodules = []
    evaluation_repo = client.create_repository(repo_name, options)
    pattern = build_regexp_from_string(params[1])
    client.organization_repositories(config['Org'].to_s).each do |repo|
      submodules << repo[:ssh_url] if pattern.match(repo[:name]) && (repo[:name] != repo_name)
    end
    unless submodules.empty?
      local_repo_path = "#{Dir.pwd}/#{repo_name}"
      FileUtils.mkdir_p(local_repo_path)
      FileUtils.cd(local_repo_path) do
        system('git init')
        submodules.each do |i|
          system("git submodule add #{i}")
        end
        system('git add .')
        system('git commit -m "First commit"')
        system("git remote add origin #{evaluation_repo[:ssh_url]}")
        system('git push -u origin master')
      end
    end
    puts Rainbow("No submodule found with /#{pattern.source}/") if submodules.empty?
  rescue StandardError => e
    puts Rainbow(e.message.to_s).color(ERROR_CODE)
  end

  def foreach_setup(client, config)
    repo_content = []
    repo_ssh_clone = []
    client.contents("#{config['Org']}/#{config['Repo']}").each do |i|
      repo_content << i[:name]
    end
    unless repo_content.include?('.gitmodules')
      puts Rainbow('Current repo does not include .gitmodules and command will not work.').color(WARNING_CODE)
      return
    end
    current_repo_info = client.repository("#{config['Org']}/#{config['Repo']}")
    repo_ssh_clone << { name: current_repo_info[:name], ssh_url: current_repo_info[:ssh_url] }
    perform_git_clone(repo_ssh_clone, nil)
  end

  # Evaluate a bash command in each submodule
  #
  # @param [Object] client Octokit client object
  # @param [Hash] config user configuration tracking current org, repo, etc.
  # @param [Array<String>] params bash command
  def foreach_eval(client, config, params)
    if config['Repo']
      foreach_setup(client, config)
      command = params.join(' ')
      FileUtils.cd("#{Dir.pwd}/#{config['Repo']}") do
        system("git submodule foreach '#{command} || :'")
      end
    else
      puts Rainbow('Please change to an organization repository to run this command.').color(INFO_CODE)
      return
    end
  rescue StandardError => e
    puts Rainbow(e.message.to_s).color(ERROR_CODE)
  end

  def foreach_try(client, config, params)
    if config['Repo']
      foreach_setup(client, config)
      command = params.join(' ')
      FileUtils.cd("#{Dir.pwd}/#{config['Repo']}") do
        system("git submodule foreach '#{command}'")
      end
    else
      puts Rainbow('Please change to an organization repository to run this command.').color(INFO_CODE)
      return
    end
  rescue StandardError => e
    puts Rainbow(e.message.to_s).color(ERROR_CODE)
  end

  # Display files and directories within a repository
  #
  # @param client [Object] Octokit client object
  # @param config [Hash] user configuration tracking current org, repo, etc.
  # @params params [String] Subdirectory within a repo, if not provided shows root directory
  def show_files(client, config, params)
    if config['Repo']
      options = { path: '' }
      options[:path] = params[0] unless params.empty?
      client.contents("#{config['Org']}/#{config['Repo']}", options).each do |i|
        puts "#{i[:name]} (#{i[:type]})"
      end
    else
      puts Rainbow('Please change to organization repository to see its files.').color(INFO_CODE)
    end
  rescue StandardError => e
    puts Rainbow(e.message.to_s).color(ERROR_CODE)
  end

  # Display organization teams
  #
  # @param client [Object] Octokit client object
  # @param config [Hash] user configuration tracking current org, repo, etc.
  # @param params [Regexp] regexp to check team name
  def show_teams(client, config, params)
    org_teams = []
    spinner = custom_spinner("Fetching #{config['Org']} teams :spinner ...")
    spinner.auto_spin
    client.organization_teams(config['Org'].to_s).each do |team|
      org_teams << team[:name]
    end
    org_teams.sort_by!(&:downcase)
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

  # Clone a repository, if repo_name is Regexp it will clone all org repositories matching pattern
  #   if repo_name is String searches for that repo and clones it
  #
  # @param enviroment [ShellContext] contains the shell context, including Octokit client and user config
  # @param repo_name [Regexp, String] pattern or name of repo
  # @param custom_path [String] if is not provided default path is HOME/ghedsh-cloned else is some
  #   path under HOME (already existing or not)
  def clone_repository(enviroment, repo_name, custom_path)
    client = enviroment.client
    config = enviroment.config
    repos_to_clone = []
    if repo_name.include?('/')
      pattern = build_regexp_from_string(repo_name)
      client.organization_repositories(config['Org'].to_s).each do |repo|
        repos_to_clone << { name: repo[:name], ssh_url: repo[:clone_url] } if pattern.match(repo[:name])
      end
      puts Rainbow("No repository matched \/#{pattern.source}\/").color(INFO_CODE) if repos_to_clone.empty?
    else
      repo = client.repository("#{config['Org']}/#{repo_name}")
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
    puts Rainbow(exception.message.to_s).color(ERROR_CODE)
    puts
  end

  # Open default browser ready to create an issue with GitHub form.
  #
  # @param config [Hash] user configuration tracking current org, repo, etc.
  # @example create issue
  #   User > Org > Repo > new_issue
  def create_issue(config)
    if config['Repo']
      issue_creation_url = "https://github.com/#{config['Org']}/#{config['Repo']}/issues/new"
      open_url(issue_creation_url)
    else
      puts Rainbow('Change to repo in order to create an issue.').color(INFO_CODE)
    end
  end

  # Add members typing them separately
  #
  # @param client [Object] Octokit client object
  # @param config [Hash] user configuration tracking current org, repo, etc.
  # @example add two members to current org (separated with commas)
  #   User > Org > invite_member member1, member2
  # @example add two members to current org (separated with blanks)
  #   User > Org > invite_member member1 member2
  # @example add members to current org (commas and blanks combined)
  #   User > Org > invite_member member1, member2 member4, member5
  def add_members(client, config, members)
    if members.empty?
      puts Rainbow('Please type each member you would like to add.').color(INFO_CODE)
    else
      people = split_members(members)
      spinner = custom_spinner('Adding member(s) :spinner ...')
      people.each do |i|
        options = { role: 'member', user: i.to_s }
        client.update_organization_membership(config['Org'].to_s, options)
      end
      spinner.stop(Rainbow('done!').color(4, 255, 0))
    end
  rescue StandardError => exception
    puts Rainbow(exception.message.to_s).color(ERROR_CODE)
  end

  # Add members from file (JSON). File must be located somewhere in HOME.
  #
  # @param client [Object] Octokit client object
  # @param config [Hash] user configuration tracking current org, repo, etc.
  def add_members_from_file(client, config, path)
    file_path = "#{Dir.home}#{path}"
    members_json = File.read(file_path)
    members_file = JSON.parse(members_json)
    spinner = custom_spinner('Adding members from file :spinner ...')
    members_file['members'].each do |member|
      options = { role: 'member', user: member['id'].to_s }
      client.update_organization_membership(config['Org'].to_s, options)
    end
    spinner.stop(Rainbow('done!').color(4, 255, 0))
  rescue Errno::ENOENT
    puts Rainbow('Could not open file, check file location.').color(ERROR_CODE)
  rescue StandardError => exception
    puts Rainbow(exception.message.to_s).color(ERROR_CODE)
  end

  # Removes a group of members form current organization. It is possible to specify them
  # in a file or with Regexp to match GitHub IDs.
  #
  # @param client [Object] Octokit client object
  # @param config [Hash] user configuration tracking current org, repo, etc.
  # @param param [String, Regexp] if string must be file path to remove memebers from file
  # if Regexp will remove matching GitHub IDs from organization
  def delete_member(client, config, param)
    permissions = client.organization_membership(config['Org'], opts = { user: client.login })
    unless permissions[:role] == 'admin'
      puts Rainbow("You must have Admin permissions on #{config['Org']} to run this command.").underline.color(WARNING_CODE)
      return
    end
    if is_file?("#{Dir.home}#{param}")
      puts 'Removing member/members from file.'
      file_path = "#{Dir.home}#{param}"
      remove_json = File.read(file_path)
      remove_member_file = JSON.parse(remove_json)
      remove_member_file['remove'].each do |member|
        client.remove_organization_member(congif['Org'], member['id'].to_s)
      end
    elsif eval(param).is_a?(Regexp)
      members_to_remove = []
      pattern = build_regexp_from_string(param)
      client.organization_members(config['Org'].to_s).each do |member|
        members_to_remove.push(member[:login]) if pattern.match(member[:login])
      end
      if members_to_remove.empty?
        puts Rainbow("No members to remove matched with \/#{pattern.source}\/").color(WARNING_CODE)
      else
        members_to_remove.each do |i|
          client.remove_organization_member(congif['Org'], i.to_s)
        end
      end
    end
  rescue SyntaxError => e
    puts Rainbow('Parameter is not a file and there was a Syntax Error building Regexp.').color(ERROR_CODE)
  rescue StandardError => e
    puts Rainbow(e.message.to_s).color(ERROR_CODE)
  end

  # Invite as members all outside collaborators from organization.
  # This action needs admin permissions on the organization.
  # This method checks first if parameter is an existing file, then checks Regexp, else invites all
  # outside collaborators of current organization.
  #
  # @param client [Object] Octokit client object
  # @param config [Hash] user configuration tracking current org, repo, etc.
  # @param param [String, Regexp] file path or Regexp to invite outside collabs
  def invite_all_outside_collaborators(client, config, param)
    permissions = client.organization_membership(config['Org'], opts = { user: client.login })
    unless permissions[:role] == 'admin'
      puts Rainbow("You must have Admin permissions on #{config['Org']} to run this command.").underline.color(WARNING_CODE)
      return
    end
    outside_collaborators = []
    spinner = custom_spinner('Sending invitations :spinner ...')
    if is_file?("#{Dir.home}#{param}")
      puts 'Adding outside collaborators from file'
      file_path = "#{Dir.home}#{param}"
      collab_json = File.read(file_path)
      collab_file = JSON.parse(collab_json)
      collab_file['collabs'].each do |collab|
        outside_collaborators.push(collab['id'])
      end
    elsif eval(param).is_a?(Regexp)
      pattern = build_regexp_from_string(param)
      client.outside_collaborators(config['Org']).each do |i|
        outside_collaborators.push(i[:login]) if pattern.match(i[:login])
      end
    else
      begin
        client.outside_collaborators(config['Org']).each do |i|
          outside_collaborators.push(i[:login])
        end
      rescue StandardError => exception
        puts Rainbow('If you entered file path, please ensure that is the correct path.').color(ERROR_CODE)
      end
    end
    outside_collaborators.each do |j|
      options = { role: 'member', user: j.to_s }
      client.update_organization_membership(config['Org'], options)
    end
    spinner.stop(Rainbow('done!').color(4, 255, 0))
  rescue SyntaxError => e
    puts Rainbow('Parameter is not a file and there was a Syntax Error building Regexp.').color(ERROR_CODE)
  rescue StandardError => exception
    puts Rainbow(exception.message.to_s).color(ERROR_CODE)
  end

  # Open default browser and shows open issues
  #
  # @param config [Hash] user configuration tracking current org, repo, etc.
  # @example open issue's list
  #   User > Org > Repo > issues
  def show_issues(config)
    if config['Repo']
      issues_url = "https://github.com/#{config['Org']}/#{config['Repo']}/issues"
      open_url(issues_url)
    else
      puts Rainbow('Change to repo in order to view all issues').color(INFO_CODE)
    end
  end

  # Display organization people. It shows all members and if the authenticated user is org admin
  #   also displays outside collaborators.
  #
  # @param client [Object] Octokit client object
  # @param config [Hash] user configuration tracking current org, repo, etc.
  # @param params [Regexp] if provided, it must be a Regexp
  # @example Display organization people
  #   User > Org > people
  # @example Display people matching Regexp
  #   User > Org > people /alu/
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
      unless params.include?('/')
        raise Rainbow('Parameter must be a Regexp. Example: /pattern/').color(ERROR_CODE)
        return
      end
      pattern = build_regexp_from_string(params)
      occurrences = build_item_table(org_members, pattern)
      puts Rainbow("No member inside #{config['Org']} matched  \/#{pattern.source}\/").color(INFO_CODE) if occurrences.zero?
    end
  end

  # perform cd to repo scope, if 'name' is a Regexp, matches are stored and then we let the user select one
  #   if is not a Regexp, check that the string provided is a vale repository name
  #
  # @param name [String, Regexp] repo name
  # @param client [Object] Octokit client object
  # @param enviroment [ShellContext] contains the shell context, including Octokit client and user config
  # @return [ShellContext] changed context is returned if there is not an error during process.
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

  # perform cd to team scope, first we retrieve all user's orgs, then we check 'name'
  #   if its a Regexp then matches are displayed on screen and user selects one (if no match warning
  #   is shown and we return nil)
  #   if 'name' is not a Regexp then it must be the full team's name so we check that is inside org_teams
  #   Last option is showing a warning and return nil (so we dont push to the stack_context)
  #
  # @param name [String, Regexp] team name
  # @param client [Object] Octokit client object
  # @param enviroment [ShellContext] contains the shell context, including Octokit client and user config
  # @return [ShellContext] changed context is returned if there is not an error during process.
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
  #   inside an organization user is allowed to change to a org repo and org team.
  #   In order to add new 'cd types' see example below.
  #
  # @param type [String] name of the navigating option (repo, org, team, etc.)
  # @param name [String, Regexp] String or Regexp to find the repository.
  # @example add 'chuchu' cd scope
  #   add to cd_scopes = {'chuchu => method(:cd_chuchu)}
  #   call it with (name, client, enviroment) parameters
  def cd(type, name, client, enviroment)
    cd_scopes = { 'repo' => method(:cd_repo), 'team' => method(:cd_team) }
    cd_scopes[type].call(name, client, enviroment)
  end

  # Show commits of current repo. If user is not in a repo, repository name for commit showing must be provided.
  #
  # @param enviroment [ShellContext] contains the shell context, including Octokit client and user config
  # @param params [Array<String>] if user is not on a repo then params[0] is repo name. Optionally,
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
  #
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
  #
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

  # Removes a group of GitHub users from an organization
  #
  #
  def remove_org_member; end

  # Team creation: opens team creation page on default browser when calling new_team
  #   with no options. If option provided, it must be the directory and name of the JSON file
  #   somewhere in your HOME directory for bulk creation of teams and members.
  #
  # @param client [Object] Octokit client object
  # @param config [Hash] user configuration tracking current org, repo, etc.
  # @param params [Array<String>] user specified parameters, if not nil must be path to teams JSON file.
  # @example Open current org URL and create new team
  #   User > Org > new_team
  # @example Create multiple teams with its members inside current org
  #   User > Org > new_team (HOME)/path/to/file/creation.json
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
        puts Rainbow(e.message.to_s).color(ERROR_CODE)
      end
    end
  end

  # Open org's team list and delete manually (faster than checking teams IDs and delete it)
  #
  # @param client [Object] Octokit client object
  # @param config [Hash] user configuration tracking current org, repo, etc.
  def remove_team(config)
    teams_url = "https://github.com/orgs/#{config['Org']}/teams"
    open_url(teams_url)
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
end
