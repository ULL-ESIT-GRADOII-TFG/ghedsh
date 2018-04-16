require 'readline'
require 'octokit'
require 'json'
require 'require_all'
require_rel '.'

class Team
  attr_accessor :teamlist; :groupsteams
  
  def self.shell_prompt(config)
    if config['Repo'].nil?
      Rainbow("#{config['User']}> ").aqua << Rainbow("#{config['Org']}> ").magenta << Rainbow("#{config['Team']}> ").color('#eeff41')
    else
      Rainbow("#{config['User']}> ").aqua + Rainbow("#{config['Org']}> ").magenta << Rainbow("#{config['Team']}> ").color('#eeff41') << Rainbow("#{config['Repo']}> ").color(236, 151, 21)
    end
  end

  def build_cd_syntax(type, name)
    syntax_map = { 'repo' => "Team.new.cd('repo', #{name}, client, env)" }
    unless syntax_map.key?(type)
      raise Rainbow("cd #{type} currently not supported.").color('#cc0000')
    end
    syntax_map[type]
  end

  def open_info(config, params = nil, client = nil)
    if config['Repo'].nil?
      open_url(config['team_url'].to_s)
    else
      open_url(config['repo_url'].to_s)
    end
  end

  def add_to_team(client, config, path)
    client.add_team_member(config['TeamID'], path)
  end

  def read_teamlist(client, config)
    @teamlist = {}
    mem = client.organization_teams(config['Org'])
    mem.each do |i|
      @teamlist[i.name] = i[:id]
    end
    @teamlist
  end

  def get_teamlist
    @teamlist
  end

  def clean_groupsteams # metodo para limpiar la cache en cd ..
    @groupsteams = {}
  end

  def create_team(client, config, name)
    client.create_team(config['Org'], name: name, permission: 'push')
  rescue StandardError
    puts 'Already exists a team with that name'
  end

  def create_team_with_members(client, config, name, members)
    t = create_team(client, config, name)
    unless t.nil?
      config['TeamID'] = t[:id]

      for i in 0..members.size
        if client.organization_member?(config['Org'], members[i])
          add_to_team(client, config, members[i])
        end
      end
    end
  end

  def add_to_team(client, config, path)
    client.add_team_member(config['TeamID'], path)
  end

  def delete_team(client, name)
    client.delete_team(name)
  end

  def show_teams_bs(client, config)
    print "\n"
    mem = client.organization_teams(config['Org'])
    mem.each do |i|
      puts i.name
    end
    print "\n"
  end

  def show_team_members_bs(client, config)
    print "\n"
    memberlist = []
    mem = client.team_members(config['TeamID'])
    mem.each do |i|
      m = eval(i.inspect)
      puts m[:login]
      memberlist.push(m[:login])
    end
    print "\n"
    return memberlist
    print "\n"
  end

  def get_team_members(client, config, team)
    memberlist = []
    read_teamlist(client, config) if @teamlist.empty?

    unless @teamlist[team.to_s].nil?
      mem = client.team_members(@teamlist[team.to_s])
      mem.each do |i|
        m = eval(i.inspect)
        memberlist.push(m[:login])
      end
    end
    memberlist
  end

  def list_groups(client, config)
    sys = Sys.new
    list = sys.load_groups("#{ENV['HOME']}/.ghedsh")
    groups = list['orgs'].detect { |aux| aux['name'] == config['Org'] }
    if !groups.nil?
      if groups['groups'].empty?
        puts 'No groups are available yet'
      else
        puts "\nGroup\tTeams\tMembers"
        groups['groups'].each do |i|
          puts "\n"
          puts i['name_group']
          i['teams'].each do |j|
            puts "\t#{j}"
            if @groupsteams[j.to_s].nil?
              @groupsteams[j.to_s] = []
              get_team_members(client, config, j).each do |k|
                puts "\t\t#{k}"
                @groupsteams[j.to_s].push(k)
              end
            else
              @groupsteams[j.to_s].each do |k|
                puts "\t\t#{k}"
              end
            end
          end
        end
      end
    else
      puts 'No groups are available yet'
      list['orgs'].push('name' => config['Org'], 'groups' => [])
      sys.save_groups("#{ENV['HOME']}/.ghedsh", list)
    end
  end

  def get_groupslist(config)
    sys = Sys.new
    grouplist = []
    list = sys.load_groups("#{ENV['HOME']}/.ghedsh")
    groups = list['orgs'].detect { |aux| aux['name'] == config['Org'] }
    groups['groups'].each do |i|
      grouplist.push(i['name_group'])
    end
    grouplist
  end

  def get_single_group(config, wanted)
    sys = Sys.new
    list = sys.load_groups("#{ENV['HOME']}/.ghedsh")
    w = list['orgs'].detect { |aux| aux['name'] == config['Org'] }
    w = w['groups'].detect { |aux| aux['name_group'] == wanted }
    if !w.nil?
      return w['teams']
    else
      return nil
    end
  end

  def new_group_file(client, config, name, file)
    sys = Sys.new
    list = sys.loadfile(file)
    if !list.nil?
      new_group(client, config, name, list)
    else
      puts "The file doesn't exist or It's empty."
    end
  end

  def new_group(client, config, name, listgroups)
    sys = Sys.new
    list = sys.load_groups("#{ENV['HOME']}/.ghedsh")
    groups = list['orgs'].detect { |aux| aux['name'] == config['Org'] }

    if groups.nil?
      list['orgs'].push('name' => config['Org'], 'groups' => [])
      sys.save_groups("#{ENV['HOME']}/.ghedsh", list)
    end

    read_teamlist(client, config) if @teamlist.empty?

    listgroups.each do |item|
      if @teamlist[item.to_s].nil?
        listgroups.delete(item)
        puts "#{item} is not a team available."
      end
    end

    if listgroups.empty? == false
      begin
        list['orgs'][list['orgs'].index { |aux| aux['name'] == config['Org'] }]['groups'].push('name_group' => name, 'teams' => listgroups)
      rescue Exception => e
        puts e
      end
      sys.save_groups("#{ENV['HOME']}/.ghedsh", list)
    end
  end

  def delete_group(config, name)
    sys = Sys.new
    list = sys.load_groups("#{ENV['HOME']}/.ghedsh")
    groups = list['orgs'].detect { |aux| aux['name'] == config['Org'] }

    unless groups.nil?
      if groups['groups'].empty?
        puts 'No groups are available yet'
      else
        del = groups['groups'].detect { |aux| aux['name_group'] == name }
        if del.nil?
          puts 'Group not found'
        else
          puts "Group #{name} will be deleted Are your sure? (Press y to confirm)"
          op = gets.chomp
          if op == 'y'
            list['orgs'].detect { |aux| aux['name'] == config['Org'] }['groups'].delete(groups['groups'].detect { |aux2| aux2['name_group'] == name })
            sys.save_groups("#{ENV['HOME']}/.ghedsh", list)
          end
        end
      end
    end
  end

  def open_team_repos(config)
    if RUBY_PLATFORM.downcase.include?('darwin')
      system("open https://github.com/orgs/#{config['Org']}/teams/#{config['Team']}")
    elsif RUBY_PLATFORM.downcase.include?('linux')
      system("xdg-open https://github.com/orgs/#{config['Org']}/teams/#{config['Team']}")
    end
  end

  def change_group_repos_privacity; end

  def add_to_group(config, name); end

  def del_of_group(config, name)
    # list=sys.load_groups("#{ENV['HOME']}/.ghedsh")
    # list["orgs"].detect{|aux| aux["name"]==config["Org"]}["groups"].delete(groups["groups"].detect{|aux2| aux2["name_group"]==name})
  end
end
