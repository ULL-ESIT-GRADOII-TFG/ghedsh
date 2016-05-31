require 'readline'
require 'octokit'
require 'json'
require 'require_all'
require_rel '.'

class Organizations

  attr_accessor :orgslist
  attr_accessor :assiglist


  def load_assig()
    @assiglist=Hash.new()
    @assiglist=Sys.new.load_assig_db()
    return @assiglist
  end

  def show_assignements() #client,orgs
    @assiglist["Organization"].each do |org|
      puts org["name"]

      org["assignements"].each do |assig|
        puts assig["name"]
      end

    end
  end
  def get_assig()
    return @assiglist
  end

  def create_assig(client,config,data)

  end

  def add_team_to_assig(client,config,data)
    
  end
  #------------End assig. stuff------------

  def show_organization_members_bs(client,config)
    orgslist=[]
    print "\n"
    mem=client.organization_members(config["Org"])
    mem.each do |i|
      m=eval(i.inspect)
      orgslist.push(m[:login])
      puts m[:login]
    end
    return orgslist
  end

  def show_orgs(client,config)
    orgslist=[]
    print "\n"
    org=client.organizations
    org.each do |i|
      o=eval(i.inspect)
      puts o[:login]
      orgslist.push(o[:login])
    end
    print "\n"
    return orgslist
  end

  def read_orgs(client)
    orgslist=[]
    org=client.organizations
    org.each do |i|
      o=eval(i.inspect)
      orgslist.push(o[:login])
    end
    return orgslist
  end

end
