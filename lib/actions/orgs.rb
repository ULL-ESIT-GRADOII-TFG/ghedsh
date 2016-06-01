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
    @assiglist=Sys.new.load_assig_db("#{ENV['HOME']}/.ghedsh")
    return @assiglist
  end

  def show_assignments(client, config) #client,orgs
    list=self.load_assig()

    assig=list["orgs"].detect{|aux| aux["name"]==config["Org"]}
    if assig!=nil
      if assig["assigs"].empty?
        puts "No assignments are available yet"
      else
        assig["assigs"].each do |i|
          puts "\n"
          puts i["name_assig"]
          # i["teams"].each do |j|
          #     puts "\t#{j}"
          # end
        end
      end
    else
      puts "No assignments are available yet"
      list["orgs"].push({"name"=>config["Org"],"assigs"=>[]})
      Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh",list)
    end

  end

  def create_assig(client,config,name)

    puts "here"
    list=self.load_assig()
    assigs=list["orgs"].detect{|aux| aux["name"]==config["Org"]}

    if assigs==nil
      list["orgs"].push({"name"=>config["Org"],"assigs"=>[]})
      Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh",list)
    end

    begin
      list["orgs"][list["orgs"].index{|aux| aux["name"]==config["Org"]}]["assigs"].push({"name_assig"=>name,"teams"=>[],"groups"=>[],"repo"=>nil})
    rescue Exception => e
      puts e
    end
    Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh",list)

  end


  def get_assigs()
    list=self.load_assig()
    assiglist=[]
    assig=list["orgs"].detect{|aux| aux["name"]==config["Org"]}
    if assig!=nil
      if assig["assigs"].empty?
        puts "No assignments are available yet"
      else
        assig["assigs"].each do |i|
          assiglist.push(i["name_assig"])
        end
      end
    else
      list["orgs"].push({"name"=>config["Org"],"assigs"=>[]})
      Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh",list)
    end
    return assiglist
  end



  def add_team_to_assig(client,config,data)

  end

  def add_group_to_assig(client,config,data)

  end

  def add_repo_to_assig(client,config,data)

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
