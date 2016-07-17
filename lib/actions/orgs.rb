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

  def assignment_repository(client,config,name)
    ex=false
    until ex==true
      puts "\n"
      puts "Assignment: #{name}"
      puts "1) Add a repository already created "
      puts "2) Create a new empty repository"
      puts "3) Don't assign a repository yet"
      print "option => "
      op=gets.chomp
      puts "\n"
      if op=="3" or op=="1" or op=="2"
        ex=true
      end
    end
    case
    when op=="1" || op=="2"

      if op=="1"
        ex2=false
        until ex2==true
          exname=false
          until exname==true
            puts "Name of the repository -> Owner/Repository or Organization/Repository :"
            reponame=gets.chomp
            if reponame.split("/").size!=2 and reponame!=""
              puts "Please introduce a valid format."
            else
              exname=true
            end
            if reponame==""
              exname=true
              ex2=true
            end
          end
          if reponame!=""
            if client.repository?("#{reponame}")==false
              puts "\e[31m The repository #{reponame} doesn't exist\n \e[0m"
              puts "\nName of the repository (To skip and add the repository later, only press enter): "
              if reponame==""
                ex2=true
              end
            else
              ex2=true
            end
          end
        end
      end
      if op=="2"
        ex2=false
        until ex2==true
          ex2=Repositories.new().create_repository(client,config,reponame,false,ORGS)
          if ex2==false
            puts "Name of the repository (To skip and add the repository later, press enter): "
            reponame=gets.chomp
            if reponame==""
              ex2=true
            end
          end
        end
      end
    when op=="3" then reponame=""
    end
    return reponame
  end

  def assignment_groups(client,config)
    team=Teams.new()
    groupslist=team.get_groupslist(config)
    groupsadd=[]
    teamlist=team.read_teamlist(client,config)

    puts "\n"
    puts "Groups currently available:\n\n"
    puts groupslist
    puts "\nAdd groups to your assignment (Press enter to skip): "
    op=gets.chomp
    if op==""
      puts "Do you want to create a new group? (Press any key to preceed, or only enter to skip)"
      an=gets.chomp

      if an!=""
        time=Time.new
        puts "Put the name of the group (If you skip with enter, the group's name will be \"Group-#{time.ctime}\")"
        name=gets.chomp
        if name==""
           name="Group-#{time.ctime}"
           name=name.split(" ").join("-")
        end
        puts "Teams currently available:\n\n"
        teamlist.each do |aux|
          puts "#{aux[0]}"
        end
        puts "\nPut a list of Teams: "

        list=gets.chomp
        list=list.split(" ")
        team.new_group(client,config,name,list)
        groupsadd.push(name)
      else
        groupsadd=[]
      end

    else
      groupsadd=op.split(" ")
      groupsadd.each do |item|
        if groupslist.detect{|aux| aux==item}==nil
          groupsadd.delete(item)
        end
      end
    end
    return groupsadd
  end

  def create_assig(client,config,name)
    list=self.load_assig()
    assigs=list["orgs"].detect{|aux| aux["name"]==config["Org"]}

    if assigs==nil
      list["orgs"].push({"name"=>config["Org"],"assigs"=>[]})
      Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh",list)
    end

    reponame=self.assignment_repository(client,config,name)
    groupsadd=self.assignment_groups(client,config)

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
        puts "\e[31m No assignments are available yet\e[0m"
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

  def get_single_assig(config,wanted)
    list=self.load_assig()
    as=list["orgs"].detect{|aux| aux["name"]==config["Org"]}
    as=as["assigs"].detect{|aux| aux["name_assig"]==wanted}
    return as
  end

  def show_assig_info(config,assig)
    assig=self.get_single_assig(config,assig)
    puts "\n"
    puts assig["name_assig"]
    puts "Repository: #{assig["repo"]}"
    print "Groups: "
    assig["groups"].each do |y|
      print y
      print " "
    end
    puts "\n\n"
  end

  def make_assig(client,config,assig)
    web="https://github.com/"
    web2="git@github.com:"
    repo=Repositories.new()
    team=Teams.new()
    teamlist=team.read_teamlist(client,config)
    assig=self.get_single_assig(config,assig)

    if assig["repo"]!=""

      #system("git clone #{web2}#{config["Org"]}/#{assig["repo"]}.git #{ENV['HOME']}/.ghedsh/#{assig["repo"]}")
      system("git clone #{web2}#{assig["repo"]}.git #{ENV['HOME']}/.ghedsh/#{assig["repo"]}")

      assig["groups"].each do |i|
        teamsforgroup=team.get_single_group(config,i)
        teamsforgroup.each do |y|
          config["TeamID"]=teamlist["#{y}"]
          config["Team"]=y
          repo.create_repository(client,config,"#{y}-#{assig["name_assig"]}",true,TEAM)
          system("git -C #{ENV['HOME']}/.ghedsh/#{assig["repo"]} remote rm origin")
          system("git -C #{ENV['HOME']}/.ghedsh/#{assig["repo"]} remote add origin #{web2}#{config["Org"]}/#{y}-#{assig["name_assig"]}.git")

          system("git -C #{ENV['HOME']}/.ghedsh/#{assig["repo"]} push origin --all")
        end
      end
      system("rm -rf #{ENV['HOME']}/.ghedsh/#{assig["repo"]}")
    else
      puts "\e[31m No repository is given for this assignment\e[0m"
    end


  end

  def add_team_to_assig(client,config,assig,data)
    assig=self.get_single_assig(config,assig)


  end

  def add_group_to_assig(client,config,assig)
    list=self.load_assig()

    groups=self.assignment_groups(client,config)
    if groups!=""
      groups.each do |i|
        list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}["groups"].push(i)
      end
      Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh",list)
    end
  end


  def add_repo_to_assig(client,config,assig)
    list=self.load_assig()

    reponame=self.assignment_repository(client,config,assig["name_assig"])
    if reponame!=""
      list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}["repo"]=reponame
      Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh",list)
    end
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
