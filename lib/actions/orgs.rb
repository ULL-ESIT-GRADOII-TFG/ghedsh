require 'octokit'
require 'json'
require 'csv'
require 'require_all'
require_rel '.'
require_relative '../helpers'
require 'readline'

GITHUB_LIST = %w[githubid github idgithub github_id id_github githubuser github_user].freeze
MAIL_LIST = ['email', 'mail', 'e-mail'].freeze

class Organization
  attr_accessor :orgslist
  attr_accessor :peoplelist

  def load_people
    @peoplelist = {}
    @peoplelist = Sys.new.load_people_db("#{ENV['HOME']}/.ghedsh")
    @peoplelist
  end

  def self.shell_prompt(config)
    if config['Repo'].nil?
      Rainbow("#{config['User']}> ").aqua << Rainbow("#{config['Org']}> ").magenta
    else
      Rainbow("#{config['User']}> ").aqua << Rainbow("#{config['Org']}> ").magenta << Rainbow("#{config['Repo']}> ").color(236, 151, 21)
    end
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
    puts
    puts Rainbow(exception.message.to_s).color('#cc0000')
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
      puts Rainbow("No repository inside #{config['Org']} matched  \/#{pattern.source}\/").color('#00529B') if occurrences.zero?
    end
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
      puts Rainbow("No member inside #{config['Org']} matched  \/#{pattern.source}\/").color('#00529B') if occurrences.zero?
    end
  end

  def cd_repo(name, client, enviroment)
    if name.class == Regexp
      pattern = Regexp.new(name.source)
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
        puts Rainbow("No repository matched with #{name.source} inside organization #{enviroment.config['Org']}").color('#9f6000')
        puts
        return nil
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
        puts Rainbow("Maybe #{name} is not an organizaton or currently does not exist.").color('#9f6000')
        return nil
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
      pattern = Regexp.new(name.source)
      name_matches = []
      org_teams.each do |team_name|
        name_matches << team_name if pattern.match(team_name.to_s)
      end
      if name_matches.empty?
        puts Rainbow("No team matched with \/#{name.source}\/ inside organization #{enviroment.config['Org']}").color('#9f6000')
        puts
        return nil
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
        puts Rainbow("Maybe #{name} is not a #{enviroment.config['Org']} team or currently does not exist.").color('#9f6000')
        puts
        return nil
      end
    end
    enviroment
  end

  def cd(type, name, client, enviroment)
    cd_scopes = { 'repo' => method(:cd_repo), 'team' => method(:cd_team) }
    cd_scopes[type].call(name, client, enviroment)
  end

  # Takes people info froma a csv file and gets into ghedsh people information
  def add_people_info(client, config, file, relation)
    list = load_people
    csvoptions = { quote_char: '|', headers: true, skip_blanks: true }
    members = get_organization_members(client, config) # members of the organization
    change = false
    indexname = ''

    inpeople = list['orgs'].detect { |aux| aux['name'] == config['Org'] }
    if inpeople.nil?
      list['orgs'].push('name' => config['Org'], 'users' => [])
      Sys.new.save_people("#{ENV['HOME']}/.ghedsh", list)
    end

    file += '.csv' if file.end_with?('.csv') == false
    if File.exist?(file)
      begin
        mem = CSV.read(file, csvoptions)
      rescue StandardError
        print 'Invalid csv format.'
      end

      fields = mem.headers
      users = {}
      users = []
      puts "\nFields found: "
      puts fields
      puts
      mem.each do |i|
        aux = {}
        fields.each do |j|
          if !i[j].nil?
            if GITHUB_LIST.include?(j.delete('"').downcase.strip)
              data = i[j]
              data = data.delete('"')
              aux['github'] = data
              j = 'github'
            else
              if MAIL_LIST.include?(j.delete('"').downcase.strip)
                aux['email'] = i[j].delete('"').strip
                indexname = j
                j = 'email'
                change = true
              else
                data = i[j].delete('"')
                aux[j.delete('"').downcase.strip] = data.strip
              end
            end
          else
            data = i[j].delete('"')
            aux[j.delete('"').downcase.strip] = data.strip
          end
        end
        users.push(aux)
      end
      ## Aqui empiezan las diferenciaa
      if relation == true
        fields[fields.index(indexname)] = 'email' if change == true
        fields = users[0].keys
        # if users.keys.include?("github") and users.keys.include?("email") and users.keys.size==2
        if fields.include?('github') && fields.include?('email') && (fields.size == 2)
          users.each do |i|
            if members.include?(i['github'].delete('"'))
              here = list['orgs'].detect { |aux| aux['name'] == config['Org'] }['users'].detect { |aux2| aux2['github'] == i['github'] } # miro si ya esta registrado
              if here.nil?
                list['orgs'].detect { |aux| aux['name'] == config['Org'] }['users'] << i
                puts "#{i['github']} information correctly added"
              else # si ya esta registrado...
                puts "#{i['github']} is already registered in this organization"
              end
            else
              puts "#{i['github']} is not registered in this organization"
            end
          end
        else
          puts 'No relationship found between github users and emails.'
          return nil
        end
      else # insercion normal, relacion ya hecha
        users.each do |i|
          here = list['orgs'].detect { |aux| aux['name'] == config['Org'] }['users'].detect { |aux2| aux2['email'] == i['email'] }
          if !here.nil?
            i.each do |j|
              list['orgs'].detect { |aux| aux['name'] == config['Org'] }['users'].detect { |aux2| aux2['email'] == i['email'] }[(j[0]).to_s] = j[1]
            end
          else
            puts "No relation found of #{i['email']} in #{config['Org']}"
          end
        end
      end
      # tocho
      Sys.new.save_people("#{ENV['HOME']}/.ghedsh", list)
    else
      print "\n#{file} file not found.\n\n"
    end
  end

  def rm_people_info(_client, config)
    list = load_people
    inpeople = list['orgs'].detect { |aux| aux['name'] == config['Org'] }
    if inpeople.nil?
      puts 'Extended information has not been added yet'
    else
      if inpeople['users'].empty?
        puts 'Extended information has not been added yet'
      else
        list['orgs'].detect { |aux| aux['name'] == config['Org'] }['users'] = []
        Sys.new.save_people("#{ENV['HOME']}/.ghedsh", list)
        puts "The aditional information of #{config['Org']} has been removed"
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

  def show_people_info(_client, config, user)
    list = load_people

    inpeople = list['orgs'].detect { |aux| aux['name'] == config['Org'] }
    peopleinfolist = []

    if inpeople.nil?
      list['orgs'].push('name' => config['Org'], 'users' => [])
      Sys.new.save_people("#{ENV['HOME']}/.ghedsh", list)
      puts 'Extended information has not been added yet'
    else
      if inpeople['users'] != []
        if user.nil?
          fields = list['orgs'].detect { |aux| aux['name'] == config['Org'] }['users'][0].keys
          list['orgs'].detect { |aux| aux['name'] == config['Org'] }['users'].each do |i|
            puts "\n\e[31m#{i['github']}\e[0m"
            fields.each do |j|
              puts "#{j.capitalize}:\t #{i[j]}"
            end
            peopleinfolist << i['github']
          end
          return peopleinfolist
        else
          if user.include?('@')
            inuser = list['orgs'].detect { |aux| aux['name'] == config['Org'] }['users'].detect { |aux2| aux2['email'] == user }
          else
            inuser = list['orgs'].detect { |aux| aux['name'] == config['Org'] }['users'].detect { |aux2| aux2['github'] == user }
          end
          if inuser.nil?
            puts 'Not extended information has been added of that user.'
          else
            fields = inuser.keys
            puts "\n\e[31m#{inuser['github']}\e[0m"
            fields.each do |j|
              puts "#{j.capitalize}:\t #{inuser[j]}"
            end
            puts
          end
        end
      else
        puts 'Extended information has not been added yet'
      end
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

  def show_orgs(client, _config)
    orgslist = []
    print "\n"
    org = client.organizations
    org.each do |i|
      o = eval(i.inspect)
      puts o[:login]
      orgslist.push(o[:login])
    end
    print "\n"
    orgslist
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

  def open_user_url(_client, config, user, field)
    list = load_people
    inpeople = list['orgs'].detect { |aux| aux['name'] == config['Org'] }
    found = 0

    if inpeople.nil?
      list['orgs'].push('name' => config['Org'], 'users' => [])
      Sys.new.save_people("#{ENV['HOME']}/.ghedsh", list)
      puts 'Extended information has not been added yet'
    else
      if user.downcase.start_with?('/') && (user.downcase.count('/') == 2)
        sp = user.split('/')
        exp = Regexp.new(sp[1], sp[2])
        inuser = Sys.new.search_rexp_peoplehash(list['orgs'].detect { |aux| aux['name'] == config['Org'] }['users'], exp)
        user.slice!(0); user = user.chop
      else
        inuser = []
        inuser.push(list['orgs'].detect { |aux| aux['name'] == config['Org'] }['users'].detect { |aux2| aux2['github'] == user })
      end
      if inuser.nil?
        puts 'Not extended information has been added of that user.'
      else
        if field.nil?
          inuser.each do |i|
            i.each_value do |j|
              next unless j.include?('github.com')
              if !j.include?('https://') && !j.include?('http://')
                Sys.new.open_url('https://' + j)
              else
                Sys.new.open_url(j)
              end
              found = 1
            end
          end
          if found == 0
            puts 'No github web profile in the aditional information'
          end
        else
          if inuser != []
            if field.downcase.start_with?('/') && field.downcase.end_with?('/') # #regexp
              field = field.delete('/')
              inuser.each do |i|
                next if i.nil?
                i.each_value do |j|
                  next unless j.include?(field)
                  if j.include?('https://') || j.include?('http://')
                    Sys.new.open_url(j)
                  end
                end
              end
            else
              inuser.each do |_i|
                if inuser.keys.include?(field.downcase)
                  if inuser[field.downcase].include?('https://') || inuser[field.downcase].include?('http://')
                    url = inuser[field.downcase.to_s]
                  else
                    url = 'http://' + inuser[field.downcase.to_s]
                  end
                  Sys.new.open_url(url)
                else
                  puts 'No field found with that name'
                end
              end
            end
          else
            puts 'No field found with that name'
          end
        end
      end
    end
  end
end
