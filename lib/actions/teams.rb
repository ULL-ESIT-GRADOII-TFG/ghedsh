require 'readline'
require 'octokit'
require 'json'
require 'require_all'
require_rel '.'

class Teams
  attr_accessor :teamlist; :groupsteams

  def initialize
    @teamlist=Hash.new
    @groupsteams=Hash.new
  end

  def add_to_team(client,config,path)
    client.add_team_member(config["TeamID"],path)
  end

  def read_teamlist(client,config)
    @teamlist=Hash.new
    mem=client.organization_teams(config["Org"])
      mem.each do |i|
        @teamlist[i.name]=i[:id]
      end
    return @teamlist
  end

  def get_teamlist()
    return @teamlist
  end

  def clean_groupsteams()   #metodo para limpiar la cache en cd ..
    @groupsteams=Hash.new
  end

  def create_team(client,config,name)
    begin
      client.create_team(config["Org"],{:name=>name,:permission=>'push'})
    rescue
      puts "Already exists a team with that name"
    end
  end

  def create_team_with_members(client,config,name,members)
    t=self.create_team(client,config,name)
    if t!=nil
      config["TeamID"]=t[:id]

        for i in 0..members.size
          if client.organization_member?(config["Org"],members[i])
            self.add_to_team(client,config,members[i])
          end
        end
    end
  end

  def add_to_team(client,config,path)
    client.add_team_member(config["TeamID"],path)
  end

  def delete_team(client,name)
    client.delete_team(name)
  end

  def show_teams_bs(client,config)
    print "\n"
    mem=client.organization_teams(config["Org"])
      mem.each do |i|
        puts i.name
      end
    print "\n"
  end

  def show_team_members_bs(client,config)
    print "\n"
    memberlist=[]
    mem=client.team_members(config["TeamID"])
    mem.each do |i|
      m=eval(i.inspect)
      puts m[:login]
      memberlist.push(m[:login])
    end
    print "\n"
    return memberlist
    print "\n"
  end

  def get_team_members(client,config,team)
    memberlist=[]
    if @teamlist.empty?
      self.read_teamlist(client,config)
    end

    if @teamlist["#{team}"]!=nil
      mem=client.team_members(@teamlist["#{team}"])
      mem.each do |i|
        m=eval(i.inspect)
        memberlist.push(m[:login])
      end
    end
    return memberlist
  end

  def list_groups(client,config)
    sys=Sys.new()
    list=sys.load_groups("#{ENV['HOME']}/.ghedsh")
    groups=list["orgs"].detect{|aux| aux["name"]==config["Org"]}
    if groups!=nil
      if groups["groups"].empty?
        puts "No groups are available yet"
      else
        puts "\nGroup\tTeams\tMembers"
        groups["groups"].each do |i|
          puts "\n"
          puts i["name_group"]
          i["teams"].each do |j|
              puts "\t#{j}"
              if @groupsteams["#{j}"]==nil
                @groupsteams["#{j}"]=Array.new
                self.get_team_members(client,config,j).each do |k|
                  puts "\t\t#{k}"
                  @groupsteams["#{j}"].push(k)
                end
              else
                @groupsteams["#{j}"].each do |k|
                    puts "\t\t#{k}"
                end
              end
          end
        end
      end
    else
      puts "No groups are available yet"
      list["orgs"].push({"name"=>config["Org"],"groups"=>[]})
      sys.save_groups("#{ENV['HOME']}/.ghedsh",list)
    end
  end

  def get_groupslist(config)
    sys=Sys.new()
    grouplist=[]
    list=sys.load_groups("#{ENV['HOME']}/.ghedsh")
    groups=list["orgs"].detect{|aux| aux["name"]==config["Org"]}
    groups["groups"].each do |i|
      grouplist.push(i["name_group"])
    end
    return grouplist
  end

  def get_single_group(config,wanted)
    sys=Sys.new()
    list=sys.load_groups("#{ENV['HOME']}/.ghedsh")
    w=list["orgs"].detect{|aux| aux["name"]==config["Org"]}
    w=w["groups"].detect{|aux| aux["name_group"]==wanted}
    if w!=nil
      return w["teams"]
    else
      return nil
    end
  end

  def new_group_file(client,config,name,file)
    sys=Sys.new()
    list=sys.loadfile(file)
    if list!=nil
      self.new_group(client,config,name,list)
    else
      puts "The file doesn't exist or It's empty."
    end
  end

  def new_group(client,config,name,listgroups)
    sys=Sys.new()
    list=sys.load_groups("#{ENV['HOME']}/.ghedsh")
    groups=list["orgs"].detect{|aux| aux["name"]==config["Org"]}

    if groups==nil
      list["orgs"].push({"name"=>config["Org"],"groups"=>[]})
      sys.save_groups("#{ENV['HOME']}/.ghedsh",list)
    end

    if @teamlist.empty?
      self.read_teamlist(client,config)
    end

    listgroups.each do |item|
      if @teamlist["#{item}"]==nil
        listgroups.delete(item)
        puts "#{item} is not a team available."
      end
    end

    if listgroups.empty? == false
      begin
        list["orgs"][list["orgs"].index{|aux| aux["name"]==config["Org"]}]["groups"].push({"name_group"=>name,"teams"=>listgroups})
      rescue Exception => e
        puts e
      end
      sys.save_groups("#{ENV['HOME']}/.ghedsh",list)
    end
  end

  def delete_group(config,name)
    sys=Sys.new()
    list=sys.load_groups("#{ENV['HOME']}/.ghedsh")
    groups=list["orgs"].detect{|aux| aux["name"]==config["Org"]}

    if groups!=nil
      if groups["groups"].empty?
        puts "No groups are available yet"
      else
        del=groups["groups"].detect{|aux| aux["name_group"]==name}
        if del==nil
          puts "Group not found"
        else
          puts "Group #{name} will be deleted Are your sure? (Press y to confirm)"
          op=gets.chomp
          if op=="y"
            list["orgs"].detect{|aux| aux["name"]==config["Org"]}["groups"].delete(groups["groups"].detect{|aux2| aux2["name_group"]==name})
            sys.save_groups("#{ENV['HOME']}/.ghedsh",list)
          end
        end
      end
    end
  end

  def open_team_repos(config)
    case
    when RUBY_PLATFORM.downcase.include?("darwin")
      system("open https://github.com/orgs/#{config["Org"]}/teams/#{config["Team"]}")
    when RUBY_PLATFORM.downcase.include?("linux")
      system("xdg-open https://github.com/orgs/#{config["Org"]}/teams/#{config["Team"]}")
    end
  end

  def change_group_repos_privacity()
  end

  def add_to_group(config,name)
  end

  def del_of_group(config,name)
    #list=sys.load_groups("#{ENV['HOME']}/.ghedsh")
    #list["orgs"].detect{|aux| aux["name"]==config["Org"]}["groups"].delete(groups["groups"].detect{|aux2| aux2["name_group"]==name})
  end
end
