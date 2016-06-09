require 'readline'
require 'octokit'
require 'json'
require 'require_all'
require_rel '.'
require 'readline'

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
          puts "Repository: #{i["repo"]}"
          print "Groups: "
          i["groups"].each do |y|
            print y
            print " "
          end
          print "\n"
        end
      end
    else
      puts "No assignments are available yet"
      list["orgs"].push({"name"=>config["Org"],"assigs"=>[]})
      Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh",list)
    end

  end

  def create_assig(client,config,name)
    list=self.load_assig()
    assigs=list["orgs"].detect{|aux| aux["name"]==config["Org"]}

    if assigs==nil
      list["orgs"].push({"name"=>config["Org"],"assigs"=>[]})
      Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh",list)
    end

    ex=false
    until ex==true
      puts "Assignment: #{name}"
      puts "1) Add a repository already created "
      puts "2) Create a new empty repository"
      puts "3) Don't assign a repository yet"
      print "option => "
      op=gets.chomp
      if op=="3" or op=="1" or op=="2"
        ex=true
      end
    end

    case
    when op=="1" || op=="2"
      puts "Name of the repository: "
      reponame=gets.chomp
      if client.repository?("#{config["Org"]}/#{reponame}")==false
        puts "The repository #{reponame} doesn't exist"
        reponame=nil
      end
      if op=="2"
        Repositories.new().create_repository(client,config,reponame,ORGS)
      end
    when op=="3" then reponame=""
    end

    groupslist=Teams.new().get_groupslist(config)
    puts "Add groups to your assignment (Press enter to skip): "
    op=gets.chomp
    if op!=nil

      groupsadd=op.split(" ")
      groupsadd.each do |item|
        if groupslist.detect{|aux| aux==item}==nil
          groupsadd.delete(item)
        end
      end
    else
      groupsadd=[]
    end

    begin
      list["orgs"][list["orgs"].index{|aux| aux["name"]==config["Org"]}]["assigs"].push({"name_assig"=>name,"teams"=>[],"groups"=>groupsadd,"repo"=>reponame})
    rescue Exception => e
      puts e
    end
    Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh",list)
  end

  def get_assigs(client,config)
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
    options=Hash.new
    options[:organization]=config["Org"]
    options[:auto_init]=true

    client.create_repository(data,options)

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
