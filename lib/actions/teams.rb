require 'readline'
require 'octokit'
require 'json'
require 'require_all'
require_rel '.'

class Teams
  attr_accessor :teamlist

  def list_team_repos(repos)

  end

  def add_to_team(client,config,path)
    client.add_team_member(config["TeamID"],path)
  end

  def read_teamlist(client,config)
    @teamlist=Hash.new
    mem=client.organization_teams(config["Org"])
      mem.each do |i|
        @teamlist[i.name]=i[:id]
        #self.add_history(i.name)
      end
    return @teamlist
  end

  def get_teamlist()
    return @teamlist
  end

  def create_team(client,config,name)
    client.create_team(config["Org"],{:name=>name,:permission=>'push'})
  end

  def create_team_with_members(client,config,name,members)
    t=self.create_team(client,config,name)
    config["TeamID"]=t[:id]

      for i in 0..members.size
        self.add_to_team(client,config,members[i])
      end
  end

  def delete_team(client,name)
    client.delete_team(name)
  end

  def show_teams_bs(client,config)
    print "\n"
    mem=client.organization_teams(config["Org"])
      mem.each do |i|
        puts i.name
        #print "ID: ",i[:id],"\n"
      end
    print "\n"

  end


end
