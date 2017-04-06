require 'readline'
require 'octokit'
require 'json'
require 'csv'
require 'require_all'
require_rel '.'
require 'readline'

GITHUB_LIST=['githubid','idgithub','github_id','id_github','githubuser','github_user']
MAIL_LIST=['email','mail','e-mail']

class Organizations

  attr_accessor :orgslist
  attr_accessor :assiglist
  attr_accessor :peoplelist


  def load_assig()
    @assiglist=Hash.new()
    @assiglist=Sys.new.load_assig_db("#{ENV['HOME']}/.ghedsh")
    return @assiglist
  end

  def load_people()
    @peoplelist=Hash.new()
    @peoplelist=Sys.new.load_people_db("#{ENV['HOME']}/.ghedsh")
    return @peoplelist
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
          puts "\tRepository: #{i["repo"]}"
          puts "\tGroups: "
          i["groups"].each do |y|
            puts "\t\t#{y}"
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
          puts "Name of the repository (To skip and add the repository later, press enter): "
          reponame=gets.chomp
          if reponame==""
            ex2=true
          else
            ex2=Repositories.new().create_repository(client,config,reponame,false,ORGS)
            reponame="#{config["Org"]}/#{reponame}"
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
    groupslist.each do |aux|
      puts "\t#{aux}"
    end
    #puts groupslist
    puts "\nAdd groups to your assignment (Press enter to skip): "
    op=gets.chomp
    if op==""
      puts "Do you want to create a new group? (Press any key and enter to proceed, or only enter to skip)"
      an=gets.chomp

      if an!=""
        time=Time.new
        puts "Put the name of the group (If you skip with enter, the group's name will be \"Group-#{time.ctime}\")"
        name=gets.chomp
        if name==""
           name="Group-#{time.ctime}"
           name=name.split(" ").join("-")
        end
        puts "\nTeams currently available:\n\n"
        teamlist.each do |aux|
          puts "\t#{aux[0]}"
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
    team=Teams.new()
    puts "\n"
    puts assig["name_assig"]
    puts "\tRepository: #{assig["repo"]}"
    puts "\tGroups: "
    assig["groups"].each do |y|
      puts "\t\t#{y}"
      t=team.get_single_group(config,y)
      t.each do |z|
        puts "\t\t\t#{z}"
      end
    end
    puts "\n"
  end

  def make_assig(client,config,assig)
    web="https://github.com/"
    web2="git@github.com:"
    repo=Repositories.new()
    team=Teams.new()
    sys=Sys.new()
    teamlist=team.read_teamlist(client,config)
    assig=self.get_single_assig(config,assig)

    if assig["repo"]!=""
      sys.create_temp("#{ENV['HOME']}/.ghedsh/temp")

      #system("git clone #{web2}#{config["Org"]}/#{assig["repo"]}.git #{ENV['HOME']}/.ghedsh/#{assig["repo"]}")
      system("git clone #{web2}#{assig["repo"]}.git #{ENV['HOME']}/.ghedsh/temp/#{assig["repo"]}")

      assig["groups"].each do |i|
        teamsforgroup=team.get_single_group(config,i)
        teamsforgroup.each do |y|
          config["TeamID"]=teamlist["#{y}"]
          config["Team"]=y
          repo.create_repository(client,config,"#{y}-#{assig["name_assig"]}",true,TEAM)
          system("git -C #{ENV['HOME']}/.ghedsh/temp/#{assig["repo"]} remote rm origin")
          system("git -C #{ENV['HOME']}/.ghedsh/temp/#{assig["repo"]} remote add origin #{web2}#{config["Org"]}/#{y}-#{assig["name_assig"]}.git")

          system("git -C #{ENV['HOME']}/.ghedsh/temp/#{assig["repo"]} push origin --all")
        end
      end
      #system("rm -rf #{ENV['HOME']}/.ghedsh/temp/#{assig["repo"]}")
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

  #Takes people info froma a csv file and gets into ghedsh people information
  def add_people_info(client,config,file)
    list=self.load_people()
    csvoptions={:quote_char => "|",:headers=>true,:skip_blanks=>true}
    members=self.get_organization_members(client,config)  #members of the organization

    inpeople=list["orgs"].detect{|aux| aux["name"]==config["Org"]}
    if inpeople==nil
      list["orgs"].push({"name"=>config["Org"],"users"=>[]})
      Sys.new.save_people("#{ENV['HOME']}/.ghedsh",list)
    end

    if file.end_with?(".csv")==false
      file=file+".csv"
    end
    if File.exist?(file)
      begin
        mem = CSV.read(file,csvoptions)
      rescue
        print "Invalid csv format."
      end
      fields=mem.headers
      users=Hash.new;
      users=[]
      puts "\nFields found: "
      puts fields
      puts
      mem.each do |i|
        aux=Hash.new
        fields.each do |j|
          if i[j]!=nil
            if GITHUB_LIST.include?(j.gsub("\"", "").downcase.strip)
              aux["github"]=i[j].gsub("\"", "").strip
            else
              if MAIL_LIST.include?(j.gsub("\"", "").downcase.strip)
                aux["email"]=i[j].gsub("\"", "").strip
              else
                aux[j.gsub("\"", "").downcase.strip]=i[j].gsub("\"", "").strip
              end
            end
          else
            aux[j.gsub("\"", "").downcase.strip]=i[j]
          end
        end
        users<< aux
      end

      users.each do |i|
        if members.include?(i["github"])
          here=list["orgs"].detect{|aux| aux["name"]==config["Org"]}["users"].detect{|aux2| aux2["github"]==i["github"]}
          if here==nil
            list["orgs"].detect{|aux| aux["name"]==config["Org"]}["users"]<<i
            puts "#{i["github"]} information correctly added"
          else
            puts "\nAlready exits \e[31m#{i["github"]}\e[0m in database"
            if here.eql?(i)
              puts "The information given is the same as in the database, changes are being discard."
            else
              puts "The information is different thant the original. Do you want to change it?"
              puts "\n Github:\t#{here["github"]} -> #{i["github"]}"

              fields.each do |j|
                puts " #{j} :\t\t#{here[j.gsub("\"", "").downcase]} -> #{i[j.gsub("\"", "").downcase]}"
              end

              puts "\nPress any key and enter to proceed, or only enter to skip: "
              op=gets.chomp
              if op!=""
                index1=list["orgs"].index{|aux| aux["name"]==config["Org"]}
                index2=list["orgs"][index1]["users"].index{|aux2| aux2["github"]==i["github"]}

                list["orgs"][index1]["users"].pop(index2)
                list["orgs"].detect{|aux| aux["name"]==config["Org"]}["users"]<<i
                puts "The information about \e[31m#{i["github"]}\e[0m has been changed"
              else
                puts "The new information about \e[31m#{i["github"]}\e[0m has been discarded"
              end
            end
          end
        else
          puts "#{i["github"]} is not registered in this organization"
        end
      end
      Sys.new.save_people("#{ENV['HOME']}/.ghedsh",list)
    else
      print "\n#{file} file not found.\n\n"
    end
  end

  def rm_people_info(client,config)
    list=self.load_people()
    inpeople=list["orgs"].detect{|aux| aux["name"]==config["Org"]}
    if inpeople==nil
      puts "Extended information has not been added yet"
    else
      if inpeople["users"].empty?
        puts "Extended information has not been added yet"
      else
        list["orgs"].detect{|aux| aux["name"]==config["Org"]}["users"]=[]
        Sys.new.save_people("#{ENV['HOME']}/.ghedsh",list)
        puts "The aditional information of #{config["Org"]} has been removed"
      end
    end
  end

  def show_people_info(client,config,user)
    list=self.load_people()

    inpeople=list["orgs"].detect{|aux| aux["name"]==config["Org"]}
    peopleinfolist=[]

    if inpeople==nil
      list["orgs"].push({"name"=>config["Org"],"users"=>[]})
      Sys.new.save_people("#{ENV['HOME']}/.ghedsh",list)
      puts "Extended information has not been added yet"
    else
      if inpeople["users"]!=[]
        if user==nil
          fields=list["orgs"].detect{|aux| aux["name"]==config["Org"]}["users"][0].keys
          list["orgs"].detect{|aux| aux["name"]==config["Org"]}["users"].each do |i|
            puts "\n\e[31m#{i["github"]}\e[0m"
            fields.each do |j|
              puts "#{j.capitalize}:\t #{i[j]}"
            end
            peopleinfolist<<i["github"]
          end
          return peopleinfolist
        else
          if user.include?("@")
            inuser=list["orgs"].detect{|aux| aux["name"]==config["Org"]}["users"].detect{|aux2| aux2["email"]==user}
          else
            inuser=list["orgs"].detect{|aux| aux["name"]==config["Org"]}["users"].detect{|aux2| aux2["github"]==user}
          end
          if inuser==nil
            puts "Not extended information has been added of that user."
          else
            fields=inuser.keys
            puts "\n\e[31m#{inuser["github"]}\e[0m"
            fields.each do |j|
              puts "#{j.capitalize}:\t #{inuser[j]}"
            end
            puts
          end
        end
      else
        puts "Extended information has not been added yet"
      end
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
    puts
    return orgslist
  end

  def get_organization_members(client,config)
    mem=client.organization_members(config["Org"])
    list=[]
    if mem!=nil
      mem.each do |i|
        list<<i[:login]
      end
    end
    return list
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

  def open_org(client,config)
    mem=client.organization(config["Org"])
    Sys.new.open_url(mem[:html_url])
  end

  def open_user_url(client,config,user,field)
    list=self.load_people()
    inpeople=list["orgs"].detect{|aux| aux["name"]==config["Org"]}
    found=0

    if inpeople==nil
      list["orgs"].push({"name"=>config["Org"],"users"=>[]})
      Sys.new.save_people("#{ENV['HOME']}/.ghedsh",list)
      puts "Extended information has not been added yet"
    else
      inuser=list["orgs"].detect{|aux| aux["name"]==config["Org"]}["users"].detect{|aux2| aux2["github"]==user}
      if inuser==nil
        puts "Not extended information has been added of that user."
      else
        if field==nil
          inuser.each_value do |j|
            if j.include?("github.com")
              if !j.include?("https://") && !j.include?("http://")
                Sys.new.open_url("https://"+j)
              else
                Sys.new.open_url(j)
              end
              found=1
            end
          end
          if found==0
            puts "No github web profile in the aditional information"
          end
        else
          if inuser.keys.include?(field.downcase)
            if inuser[field.downcase].include?("https://")==false || inuser[field.downcase].include?("http://")==false
              url="http://"+inuser["#{field.downcase}"]
            else
              url=inuser["#{field.downcase}"]
            end
            Sys.new.open_url(url)
          else
            puts "No field found with that name"
          end
        end
      end
    end
  end

end
