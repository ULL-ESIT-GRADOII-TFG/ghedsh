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
          i.each{|key, value| if key.include?("repo") then  puts "Repository #{key.delete("repo")}: #{value}" end}
          if i["groups"]!=[] and i["groups"]!=nil
            puts "\tGroups: "
            i["groups"].each do |y|
              puts "\t\t#{y}"
            end
          end
          if i["people"]!=[] and i["people"]!=nil
            puts "\tStudents: "
            i["people"].each do |y|
              puts "\t\t#{y}"
            end
            puts "\n"
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
      # puts "2) Create a new empty repository"
      puts "2) Don't assign a repository yet"
      print "option => "
      op=gets.chomp
      puts "\n"
      if op=="1" or op=="2"
        ex=true
      end
    end
    case
    when op=="1"

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
    when op=="2" then reponame=""
    end
    return reponame
  end

  def assignment_groups(client,config)
    team=Teams.new()
    sys=Sys.new()
    groupslist=team.get_groupslist(config)
    groupsadd=[]
    teamlist=team.read_teamlist(client,config)

    puts "\n"
    puts "Groups currently available:\n\n"
    groupslist.each do |aux|
      puts "\t#{aux}"
    end

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
        begin
          puts "\n1)Put a list of Teams"
          puts "2)Take all the Teams available"
          puts "3)Take the teams from a file\n"
          puts "4)Add the teams to the group later"
          print "option => "
          op2=gets.chomp
        end while (op2!="1" && op2!="2" && op2!="3" && op2!="4")
        refuse=false         #para no añadirlo cuando se niege en la repeticion de la busqueda de fichero
        if op2=="1"
          puts "\nPut a list of Teams (Separeted with space): "
          list=gets.chomp
          list=list.split(" ")
        end
        if op2=="2"
          puts "All the teams have been taken"
          list=teamlist.keys
        end
        if op2=="3"
          begin
            ex=2
            puts "Put the name of the file: "
            file=gets.chomp
            list=sys.loadfile(file)
            if list==nil
              puts "The file doesn't exist or It's empty. Do you like to try again? (y/n):"
              op3=gets.chomp
              if op3 == "n" or op3 == "N"
                ex=1
                refuse=true
              end
            else
              ex=1
            end
          end while ex!=1
        end
        if op!="4" and refuse==false
          team.new_group(client,config,name,list)
        end
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

  def assignment_people(client,config)
    refuse=false
    members=self.get_organization_members(client,config)
    sys=Sys.new()
    begin
      puts "\n1)Put a list of students"
      puts "2)Take all the list"
      puts "3)Take the students from a file\n"
      puts "4)Add the students later"
      print "option => "
      op2=gets.chomp
    end while (op2!="1" && op2!="2" && op2!="3" && op2!="4")
    if op2=="1"
      puts members
      puts "\nPut a list of students (Separeted with space): "
      list=gets.chomp
      list=list.split(" ")
    end
    if op2=="2"
      puts "All the students have been taken"
      list=members
    end
    if op2=="3"
      begin
        ex=2
        puts "Put the name of the file: "
        file=gets.chomp
        list=sys.loadfile(file)
        if list==nil
          puts "The file doesn't exist or It's empty. Do you like to try again? (y/n):"
          op3=gets.chomp
          if op3 == "n" or op3 == "N"
            ex=1
            refuse=true
          end
        else
          ex=1
        end
      end while ex!=1
    end
    if op2!=4 and refuse==false
      if op2!=2
        if list!=nil
          list.each do |i|
            if !members.include?(i)
              list.delete(i)
            end
          end
        end
      end
      return list
    else
      return []
    end
  end

  def create_assig(client,config,name)
    list=self.load_assig()
    assigs=list["orgs"].detect{|aux| aux["name"]==config["Org"]}

    if assigs==nil
      list["orgs"].push({"name"=>config["Org"],"assigs"=>[]})
      Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh",list)
    end

    assig_exist=list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux| aux["name_assig"]==name}
    if assig_exist==nil
      begin
        puts "\n1)Individual assignment"
        puts "2)Group assignment"
        puts "3)Discard assignment"
        print "option => "
        op=gets.chomp
      end while op!="1" && op!="2" && op!="3"

      if op!="3"
        reponame=self.assignment_repository(client,config,name)
        if op=="2"
          groupsadd=self.assignment_groups(client,config)
          peopleadd=[]
        end
        if op=="1"
          peopleadd=self.assignment_people(client,config)
          groupsadd=[]
        end
        begin
          list["orgs"][list["orgs"].index{|aux| aux["name"]==config["Org"]}]["assigs"].push({"name_assig"=>name,"teams"=>[],"people"=>peopleadd,"groups"=>groupsadd,"repo"=>reponame})
        rescue Exception => e
          puts e
        end
        Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh",list)
      end
    else
      puts "Already exists an Assignment with that name"
    end
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
    assig=assig.sort.to_h
    assig.each{|key, value| if key.include?("repo") then  puts "Repository #{key.delete("repo")}: #{value}" end}
    puts
    assig.each{|key, value| if key.include?("sufix") then  puts "Sufix of Repository #{key.delete("sufix")} : #{value}" end}
    print "\n"
    if assig["groups"]!=[]
      puts "\tGroups: "
      assig["groups"].each do |y|
        puts "\t\t#{y}"
        t=team.get_single_group(config,y)
        if t!=nil
          t.each do |z|
            puts "\t\t\t#{z}"
          end
        end
      end
    end
    if assig["people"]!=[] and assig["people"]!=nil
      puts "\tStudents: "
      assig["people"].each do |y|
        puts "\t\t#{y}"
      end
      puts "\n"
    end
  end

  def make_assig(client,config,assig)
    web="https://github.com/"
    web2="git@github.com:"
    r=Repositories.new()
    team=Teams.new()
    sys=Sys.new()
    teamlist=team.read_teamlist(client,config)
    assig=self.get_single_assig(config,assig)
    repolist=[]
    point=1
    assig.each{|key, value| if key.include?("repo") then  repolist.push(value) end}

    if repolist!=[]
      repolist.each do |repo|
        sys.create_temp("#{ENV['HOME']}/.ghedsh/temp")
        puts repo
        if repolist.size>1
          sufix="sufix#{point}"
          sufix="-#{assig["#{sufix}"]}"
        else
          sufix=""
        end
        point=point+1
        system("git clone #{web2}#{repo}.git #{ENV['HOME']}/.ghedsh/temp/#{repo}")
        if assig["groups"]!=[]
          assig["groups"].each do |i|

            teamsforgroup=team.get_single_group(config,i)
            if teamsforgroup!=nil
              teamsforgroup.each do |y|
                config["TeamID"]=teamlist["#{y}"]
                config["Team"]=y
                puts y
                puts sufix
                r.create_repository(client,config,"#{assig["name_assig"]}#{sufix}-#{y}",true,TEAM)
                system("git -C #{ENV['HOME']}/.ghedsh/temp/#{repo} remote rm origin")
                system("git -C #{ENV['HOME']}/.ghedsh/temp/#{repo} remote add origin #{web2}#{config["Org"]}/#{assig["name_assig"]}#{sufix}-#{y}.git")

                system("git -C #{ENV['HOME']}/.ghedsh/temp/#{repo} push origin --all")
              end
            end
          end
        end
        if assig["people"]!=[] and assig["people"]!=nil
          assig["people"].each do |i|
              r.create_repository(client,config,"#{assig["name_assig"]}#{sufix}-#{i}",true,ORGS)
              system("git -C #{ENV['HOME']}/.ghedsh/temp/#{repo} remote rm origin")
              system("git -C #{ENV['HOME']}/.ghedsh/temp/#{repo} remote add origin #{web2}#{config["Org"]}/#{assig["name_assig"]}#{sufix}-#{i}.git")
              system("git -C #{ENV['HOME']}/.ghedsh/temp/#{repo} push origin --all")
              r.add_collaborator(client,"#{config["Org"]}/#{assig["name_assig"]}#{sufix}-#{i}",i)
           end
        end
      end
    else
      puts "\e[31m No repository is given for this assignment\e[0m"
    end
  end

  def add_team_to_assig(client,config,assig,data)
    assig=self.get_single_assig(config,assig)
  end

  def add_people_to_assig(client,config,assig)
    list=self.load_assig()
    people=self.assignment_people(client,config)
    if list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}["people"]==nil
      list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}["people"]=[]
    end

    if people!=""
      people.each do |i|
        if !list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}["people"].include?(i)
          list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}["people"].push(i)
        else
          puts "#{i} is already in this assignment."
        end
      end
      Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh",list)
    end
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

  def open_assig(config,assig)
    Sys.new.open_url("https://github.com/search?q=org%3A#{config["Org"]}+#{assig}")
  end

  #Takes people info froma a csv file and gets into ghedsh people information
  def add_people_info(client,config,file,relation)
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
              j="github"
            else
              if MAIL_LIST.include?(j.gsub("\"", "").downcase.strip)
                aux["email"]=i[j].gsub("\"", "").strip
                j="email"
              else
                aux[j.gsub("\"", "").downcase.strip]=i[j].gsub("\"", "").strip
              end
            end
          else
            aux[j.gsub("\"", "").downcase.strip]=i[j]
          end
        end
        users.push(aux)
      end
      ## Aqui empiezan las diferenciaa
      if relation==true

        # if users.keys.include?("github") and users.keys.include?("email") and users.keys.size==2
        if fields.include?("github") and fields.include?("email") and fields.size==2
          users.each do |i|
            if members.include?(i["github"])
              here=list["orgs"].detect{|aux| aux["name"]==config["Org"]}["users"].detect{|aux2| aux2["github"]==i["github"]} #miro si ya esta registrado
              if here==nil
                list["orgs"].detect{|aux| aux["name"]==config["Org"]}["users"]<<i
                puts "#{i["github"]} information correctly added"
              else                                                                        #si ya esta registrado...
                puts "#{i["github"]} is already registered in this organization"
              end
            else
              puts "#{i["github"]} is not registered in this organization"
            end
          end
        else
          puts "No relationship found between github users and emails."
          return nil
        end
      else                                                                           #insercion normal, relacion ya hecha
        users.each do |i|
          here=list["orgs"].detect{|aux| aux["name"]==config["Org"]}["users"].detect{|aux2| aux2["email"]==i["email"]}
          if here!=nil
            i.each do |j|
              list["orgs"].detect{|aux| aux["name"]==config["Org"]}["users"].detect{|aux2| aux2["email"]==i["email"]}["#{j[0]}"]=j[1]
            end
          else
            puts "No relation found of #{i["email"]} in #{config["Org"]}"
          end
        end
      end
      #tocho
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

  def search_rexp_people_info(client,config,exp)
    list=self.load_people()
    if list!=nil
      if list["users"]!=[]
        list=list["orgs"].detect{|aux| aux["name"]==config["Org"]}
        if exp.match(/^\//)
          sp=exp.split('/')
          exp=Regexp.new(sp[1],sp[2])
        end
        list=Sys.new.search_rexp_peoplehash(list["users"],exp)

        if list!=[]
          fields=list[0].keys
          list.each do |i|
            puts "\n\e[31m#{i["github"]}\e[0m"
            fields.each do |j|
              puts "#{j.capitalize}:\t #{i[j]}"
            end
            puts
          end
        end
      else
        puts "Extended information has not been added yet"
      end
    else
      list["orgs"].push({"name"=>config["Org"],"users"=>[]})
      Sys.new.save_people("#{ENV['HOME']}/.ghedsh",list)
      puts "Extended information has not been added yet"
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

  def add_repo_to_assig(client,config,assig,change)
    list=self.load_assig()
    notexist=false

    if change!=nil      #change an specific repository
      reponumber=change
      fields=list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}.keys
      if reponumber=="1"
        if !fields.include?("repo")
          notexist=true
        end
      else
        if !fields.include?("repo"+change.to_s)
          notexist=true
        end
      end
    else                #adding new repository
      fields=list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}.keys
      reponumber=1
      ex=0
      while ex==0
        if reponumber==1
          if fields.include?("repo")
            reponumber=reponumber+1
          else
            ex=1
          end
        else
          if fields.include?("repo#{reponumber}")
            reponumber=reponumber+1
          else
            ex=1
          end
        end
      end
    end

    if notexist==true
      puts "Doesn't exist that repository"
    else
      reponame=self.assignment_repository(client,config,assig["name_assig"])
      if reponumber.to_i>1
        sufix="sufix#{reponumber}"
        sufixname=self.assignment_repo_sufix(reponumber,1)
      end
    end

    if reponame!="" and notexist==false
      if reponumber.to_i==1
        list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}["repo"]=reponame
        Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh",list)
      else
        list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}["repo#{reponumber}"]=reponame
        list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}["#{sufix}"]=sufixname
        if sufix=="sufix2" and change==nil
          sufixname=self.assignment_repo_sufix("1",2)
          list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}["sufix1"]=sufixname
        end
        Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh",list)
      end
    end
  end

  def rm_assigment_repo(config,assig,reponumber)
    list=self.load_assig()

    if reponumber==1
      if list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}["repo"]!=nil
        list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}.delete("repo")
        list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}.delete("sufix1")
        Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh",list)
      else
        puts "Doesn't exist that repository"
      end
    else
      if list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}["repo#{reponumber}"]!=nil
        list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}.delete("repo#{reponumber}")
        list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}.delete("sufix#{reponumber}")
        Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh",list)
      else
        puts "Doesn't exist that repository"
      end
    end
  end

  def rm_assigment_student(config,assig,student,mode)
    list=self.load_assig()
    if mode==1
      if list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}["people"].include?(student)
        list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}["people"].delete(student)
        puts "Student #{student} correctly deleted from the assignment"
        Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh",list)
      else
        puts "Student not found"
      end
    else
      list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}["people"].clear()
      puts "All the students has been deleted from the assignment"
      Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh",list)
    end
  end

  def rm_assigment_group(config,assig,group,mode)
    list=self.load_assig()
    if mode==1
      if list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}["groups"].include?(group)
        list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}["groups"].delete(group)
        puts "Group #{group} correctly deleted from the assignment"
        Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh",list)
      else
        puts "Group not found"
      end
    else
      list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}["groups"].clear()
      puts "All the groups has been deleted from the assignment"
      Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh",list)
    end
  end

  def assignment_repo_sufix(reponumber,order)
    op=""
    print "\n"
    if order==1
      while op=="" or op=="\n"
        puts "Add the suffix of the repository \"#{reponumber}\", in order to differentiate it from the other repositories: "
        op=gets.chomp
      end
    else
      while op=="" or op=="\n"
        puts "Add the suffix of the first repository, in order to differentiate it from the other repositories: "
        op=gets.chomp
      end
    end
    return op
  end

  def change_repo_sufix(config,assig,reponumber)
    list=self.load_assig()
    if list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}["sufix#{reponumber}"]!=nil
      if reponumber==1
        sufixname=self.assignment_repo_sufix(reponumber,2)
        sufix="sufix1"
      else
        sufixname=self.assignment_repo_sufix(reponumber,1)
        sufix="sufix#{reponumber}"
      end

      list["orgs"].detect{|aux| aux["name"]==config["Org"]}["assigs"].detect{|aux2| aux2["name_assig"]==assig}["#{sufix}"]=sufixname
      Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh",list)
    else
      puts "Doesn't exist a repository with that identifier"
    end
  end

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
            if inuser[field.downcase].include?("https://") or inuser[field.downcase].include?("http://")
              url=inuser["#{field.downcase}"]
            else
              url="http://"+inuser["#{field.downcase}"]
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
