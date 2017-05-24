#!/usr/bin/env ruby
require 'require_all'
require 'json'
require 'readline'
require 'octokit'
require 'optparse'
require 'actions/help'
require 'actions/orgs'
require 'actions/repo'
require 'actions/system'
require 'actions/teams'
require 'actions/user'
require 'version'

USER=1
ORGS=2
USER_REPO=10
ORGS_REPO=3
TEAM=4
ASSIG=6
TEAM_REPO=5

class Interface
  attr_reader :option, :sysbh
  attr_accessor :config
  attr_accessor :client
  attr_accessor :deep
  attr_accessor :memory
  attr_reader :orgs_list,:repos_list, :teamlist, :orgs_repos, :teams_repos, :repo_path, :issues_list

  def initialize
    @sysbh=Sys.new()
    @repos_list=[]; @orgs_repos=[]; @teams_repos=[]; @orgs_list=[]; @teamlist=[]
    @repo_path=''

    options=@sysbh.parse

    trap("SIGINT") { throw :ctrl_c}
    catch :ctrl_c do
      begin
        if options[:user]==nil && options[:token]==nil &&  options[:path]!=nil
          self.run(options[:path],options[:token],options[:user])
        else
          self.run("#{ENV['HOME']}/.ghedsh",options[:token],options[:user])
        end
      rescue SystemExit, Interrupt
        raise
      rescue Exception => e
        puts "exit"
        puts e
      end
    end
  end

  def prompt()
    case
      when @deep == USER then return @config["User"]+"> "
      when @deep == USER_REPO
        if @repo_path!=""
          @config["User"]+">"+ "\e[31m#{@config["Repo"]}\e[0m"+">"+"#{@repo_path}"+"> "
        else
          return @config["User"]+">"+ "\e[31m#{@config["Repo"]}\e[0m"+"> "
        end
      when @deep == ORGS then return @config["User"]+">"+ "\e[34m#{@config["Org"]}\e[0m"+"> "
      when @deep == ASSIG then return @config["User"]+">"+ "\e[34m#{@config["Org"]}\e[0m"+">"+"\e[35m#{@config["Assig"]}\e[0m"+"> "
      when @deep == TEAM then return @config["User"]+">"+"\e[34m#{@config["Org"]}\e[0m"+">"+"\e[32m#{@config["Team"]}\e[0m"+"> "
      when @deep == TEAM_REPO
        if @repo_path!=""
          return @config["User"]+">"+"\e[34m#{@config["Org"]}\e[0m"+">"+"\e[32m#{@config["Team"]}\e[0m"+">"+"\e[31m#{@config["Repo"]}\e[0m"+">"+"#{@repo_path}"+"> "
        else
          return @config["User"]+">"+"\e[34m#{@config["Org"]}\e[0m"+">"+"\e[32m#{@config["Team"]}\e[0m"+">"+"\e[31m#{@config["Repo"]}\e[0m"+"> "
        end
      when @deep == ORGS_REPO then
        if @repo_path!=""
          return @config["User"]+">"+"\e[34m#{@config["Org"]}\e[0m"+">"+"\e[31m#{@config["Repo"]}\e[0m"+">"+"#{@repo_path}"+"> "
        else
          return @config["User"]+">"+"\e[34m#{@config["Org"]}\e[0m"+">"+"\e[31m#{@config["Repo"]}\e[0m"+"> "
        end
    end
  end

  def help(opcd)
    h=HelpM.new()
    if opcd.size>1
      h.context(opcd[1..opcd.size-1],@deep)
    else
      case
        when @deep == USER
          h.user()
        when @deep == ORGS
          h.org()
        when @deep == ORGS_REPO
          h.org_repo()
        when @deep == USER_REPO
          h.user_repo()
        when @deep == TEAM
          h.orgs_teams()
        when @deep == TEAM_REPO
          h.team_repo()
        when @deep == ASSIG
          h.asssig()
      end
    end
  end

  #Go back to any level
  def cdback(returnall)
    if returnall!=true
      case
        when @deep == ORGS
          @config["Org"]=nil
          @deep=1
          @orgs_repos=[]
        when @deep == ORGS_REPO
          if @repo_path==""
            @config["Repo"]=nil
            @deep=2
          else
            aux=@repo_path.split("/")
            aux.pop
            if aux.empty?
              @repo_path=""
            else
              @repo_path=aux.join("/")
            end
          end
        when @deep == USER_REPO
          if @repo_path==""
            @config["Repo"]=nil
            @deep=1
          else
            aux=@repo_path.split("/")
            aux.pop
            if aux.empty?
              @repo_path=""
            else
              @repo_path=aux.join("/")
            end
          end
        when @deep == TEAM
          @config["Team"]=nil
          @config["TeamID"]=nil
          @teams_repos=[]
          @deep=ORGS
        when @deep == ASSIG
          @deep=ORGS
          @config["Assig"]=nil
        when @deep == TEAM_REPO
          if @repo_path==""
            @config["Repo"]=nil
            @deep=TEAM
          else
            aux=@repo_path.split("/")
            aux.pop
            if aux.empty?
              @repo_path=""
            else
              @repo_path=aux.join("/")
            end
          end
      end
    else
      @config["Org"]=nil
      @config["Repo"]=nil
      @config["Team"]=nil
      @config["TeamID"]=nil
      @config["Assig"]=nil
      @deep=1
      @orgs_repos=[]; @teams_repos=[]
      @repo_path="";
    end
  end

  #Go to the path, depends with the scope
  #if you are in user scope, first searchs Orgs then Repos, etc.
  def cd(path)
    if @deep==ORGS_REPO || @deep==USER_REPO || @deep==TEAM_REPO
      self.cdrepo(path)
    end
    o=Organizations.new
    path_split=path.split("/")
    if path_split.size==1                   ##cd con path simple
      case
      when @deep==USER
        @orgs_list=o.read_orgs(@client)
        aux=@orgs_list
        if aux.one?{|aux| aux==path}
          @config["Org"]=path
          @teamlist=Teams.new.read_teamlist(@client,@config)
          @sysbh.add_history_str(2,o.get_assigs(@client,@config,false))
          @sysbh.add_history_str(1,@teamlist)
          @deep=2
        else
          #puts "\nNo organization is available with that name"
          self.set(path)
        end
      when @deep == ORGS
         if @teamlist==[]
           @teamlist=Teams.new.read_teamlist(@client,@config)
         end
        aux=@teamlist

        if aux[path]!=nil
          @config["Team"]=path
          @config["TeamID"]=@teamlist[path]
          @deep=TEAM
        else
          #puts "\nNo team is available with that name"
          if cdassig(path)==false
            self.set(path)
          end
        end
      when @deep == TEAM
        self.set(path)
      end
    end
  end

  #set in the given path repository, first search in the list, then do the github query if list is empty
  def set(path)
    reposlist=Repositories.new()

    case
    when @deep==USER
      @config["Repo"]=path
      if @repos_list.empty? == false
        reposlist=@repos_list
      else
        reposlist=reposlist.get_repos_list(@client,@config,@deep)
      end
      if reposlist.one?{|aux| aux==path}
          @deep=USER_REPO
          puts "Set in #{@config["User"]} repository: #{path}\n\n"
      end
    when @deep==ORGS

      if @orgs_repos.empty? == false
        reposlist=@orgs_repos
      else
        reposlist=reposlist.get_repos_list(@client,@config,@deep)
      end
      if reposlist.one?{|aux| aux==path}
        @config["Repo"]=path
        @deep=ORGS_REPO
        puts "Set in #{@config["Org"]} repository: #{path}\n\n"
      end
    when @deep==TEAM

      if @teams_repos.empty? == false
        reposlist=@teams_repos
      else
        reposlist=reposlist.get_repos_list(@client,@config,@deep)
      end
      if reposlist.one?{|aux| aux==path}
        @config["Repo"]=path
        @deep=TEAM_REPO
        puts "Set in #{@config["Team"]} repository: #{path}\n\n"
      end
    end
    #if @deep==USER || @deep==ORGS || @deep==TEAM then puts "No repository is available with that name\n\n" end
    if @deep==USER || @deep==ORGS || @deep==TEAM
      puts "\nNo organization is available with that name"
      puts "\nNo team is available with that name"
      puts "No repository is available with that name\n\n"
    end
  end

  def cdrepo(path)
    r=Repositories.new()
    list=[]

    if @repo_path==""
      newpath=path
    else
      newpath=@repo_path+"/"+path
    end
    list=r.get_files(@client,@config,newpath,false,@deep)
    if list==nil
      puts "Wrong path name"
    else
      @repo_path=newpath
    end
  end

  def cdassig(path)
    o=Organizations.new()
    list=o.get_assigs(@client,@config,true)
    if list.one?{|aux| aux==path}
      @deep=ASSIG
      puts "Set in #{@config["Org"]} assignment: #{path}\n\n"
      @config["Assig"]=path
      return true
    else
      puts "No assignment is available with that name"
      return false
    end
  end

  def orgs()
    case
    when @deep==USER
      @sysbh.add_history_str(2,Organizations.new.show_orgs(@client,@config))
    when @deep==ORGS
      Organizations.new.show_orgs(@client,@config)
    end
  end

  def people()
    case
    when @deep==ORGS
      @sysbh.add_history_str(2,Organizations.new.show_organization_members_bs(@client,@config))
    when @deep==TEAM
      @sysbh.add_history_str(2,Teams.new.show_team_members_bs(@client,@config))
    end
  end

  def repos(all)
    repo=Repositories.new()
    case
      when @deep == USER
        if @repos_list.empty?
          if all==false
            list=repo.show_repos(@client,@config,USER,nil)
            @sysbh.add_history_str(2,list)
            @repos_list=list
          else
            list=repo.get_repos_list(@client,@config,USER)
            @sysbh.add_history_str(2,list)
            @repos_list=list
            puts list
          end
        else
          @sysbh.showcachelist(@repos_list,nil)
        end
      when @deep ==ORGS
        if @orgs_repos.empty?
          if all==false
            list=repo.show_repos(@client,@config,ORGS,nil)
            @sysbh.add_history_str(2,list)
            @orgs_repos=list
          else
            #list=repo.show_repos(@client,@config,ORGS)
            list=repo.get_repos_list(@client,@config,ORGS)
            @sysbh.add_history_str(2,list)
            @orgs_repos=list
            puts list
          end
        else
          @sysbh.showcachelist(@orgs_repos,nil)
        end
      when @deep==TEAM
        if @teams_repos.empty?
          if all==false
            list=repo.show_repos(@client,@config,TEAM,nil)
            @sysbh.add_history_str(2,list)
            @teams_repos=list
          else
            list=repo.show_repos(@client,@config,TEAM)
            @sysbh.add_history_str(2,list)
            @repos_list=list
            puts list
          end
        else
          @sysbh.showcachelist(@teams_repos,nil)
        end
    end
  end

  def get_teamlist(data)
    list=Array.new
    for i in 0..data.size-1
      list.push(@teamlist[data[i]])
    end
    return list
  end

  def commits()
    c=Repositories.new
    if @deep==ORGS_REPO || @deep==USER_REPO || @deep==TEAM_REPO
      c.show_commits(@client,@config,@deep)
    end
    print "\n"
  end

  def show_forks()
    c=Repositories.new
    if @deep==ORGS_REPO || @deep==USER_REPO || @deep==TEAM_REPO
      c.show_forks(@client,@config,@deep)
    end
  end

  def collaborators()
    c=Repositories.new
    if @deep==ORGS_REPO || @deep==USER_REPO || @deep==TEAM_REPO
      c.show_collaborators(@client,@config,@deep)
    end
  end

  #Main program
  def run(config_path, argv_token,user)
    ex=1
    opscript=[]
    @sysbh.write_initial_memory()
    HelpM.new.welcome()
    o=Organizations.new
    t=Teams.new
    r=Repositories.new
    s=Sys.new
    u=User.new
    # orden de búsqueda: ~/.ghedsh.json ./ghedsh.json ENV["ghedsh"] --configpath path/to/file.json

    #control de carga de parametros en el logueo de la aplicacion
    if user!=nil
      @config=s.load_config_user(config_path,user)
      @client=s.client
      if @config==nil
        ex=0
      end
      @deep=USER
    else
      @config=s.load_config(config_path,argv_token)  #retorna la configuracion ya guardada anteriormente
      @client=s.client
      @deep=s.return_deep(config_path)
      #if @deep==ORGS then @teamlist=t.get_teamlist end  #solucion a la carga de las ids de los equipos de trabajo
    end
    @sysbh.load_memory(config_path,@config)
    #@deep=USER
    if @client!=nil
      @sysbh.add_history_str(2,Organizations.new.read_orgs(@client))
    end

    while ex != 0

      if opscript.empty?
        begin
          op=Readline.readline(self.prompt,true).strip
          opcd=op.split
        rescue
          op="exit";opcd="exit"
        end
      else
        op=opscript[0]
        opcd=op.split
        opscript.shift
      end

      case
        when op == "exit" then ex=0
          @sysbh.save_memory(config_path,@config)
          s.save_cache(config_path,@config)
          s.remove_temp("#{ENV['HOME']}/.ghedsh/temp")
        when op.include?("help") && opcd[0]=="help" then self.help(opcd)
        when op == "orgs" then self.orgs()
        when op == "cd .."
          if @deep==ORGS then t.clean_groupsteams() end ##cleans groups cache
          self.cdback(false)
        when op.include?("cd assig") && opcd[0]=="cd" && opcd[1]=="assig" && opcd.size==3
          if @deep==ORGS
            self.cdassig(opcd[2])
          end
        when op == "people" then self.people()
        when op == "teams"
      	  if @deep==ORGS
      	    t.show_teams_bs(@client,@config)
      	  end
        when op == "commits" then self.commits()
        when op == "issues"
          if @deep==ORGS_REPO || @deep==USER_REPO || @deep==TEAM_REPO
            @issues_list=r.show_issues(@client,@config,@deep)
          end
        when op == "col" then self.collaborators()
        when op == "forks" then self.show_forks()
        when op == "groups"
          if @deep==ORGS
            t.list_groups(@client,@config)
            @sysbh.add_history_str(2,t.get_groupslist(@config))
          end
        when op.include?("group") && opcd[0]=="group"
          if opcd.size==2
            teams=t.get_single_group(@config,opcd[1])
            if teams!=nil
              puts "Teams in group #{opcd[1]} :"
              puts teams
            else
              puts "Group not found"
            end
          end
        when op.include?("new") && opcd[0]=="new" && opcd[1]=="team"        #new's parse
          if opcd.size==3 and @deep==ORGS
            t.create_team(@client,@config,opcd[2])
            @teamlist=t.read_teamlist(@client,@config)
            @sysbh.add_history_str(1,@teamlist)
          end
          if opcd.size>3 and @deep==ORGS
            t.create_team_with_members(@client,@config,opcd[2],opcd[3..opcd.size])
            @teamlist=t.read_teamlist(@client,@config)
            @sysbh.add_history_str(1,@teamlist)
          end
        when op.include?("new") && !op.include?("comment") && opcd[0]=="new" && opcd[1]=="issue"
          if opcd.size==2 and (@deep==ORGS_REPO || @deep==USER_REPO || @deep==TEAM_REPO)
            r.create_issue(@client,@config,@deep,config_path)
          end
        when op.include?("new") && (opcd[0]=="new" && opcd[1]=="issue" && opcd[2]=="comment")
          if opcd.size==4 and (@deep==ORGS_REPO || @deep==USER_REPO || @deep==TEAM_REPO)
            r.add_issue_cm(@client,@config,@deep,opcd[3],config_path)
          end
        when op.include?("new") && opcd[0]=="new" && opcd[1]=="people" && opcd[2]=="info"
          if @deep==ORGS  && opcd.size==4 then o.add_people_info(@client,@config,opcd[3],false) end
        when op.include?("new") && opcd[0]=="new" && opcd[1]=="repository"
          if opcd.size==3
            r.create_repository(@client,@config,opcd[2],false,@deep)
          end
        when op.include?("new relation") && opcd[0]=="new" && opcd[1]="relation"
          if opcd.size==3 and @deep==ORGS
            o.add_people_info(@client,@config,opcd[2],true)
          end
        when op.include?("new assignment") && opcd[0]=="new" && opcd[1]="assignment"
          if opcd.size==3 and @deep==ORGS
              r.create_repository_by_teamlist(@client,@config,opcd[2],opcd[3,opcd.size],self.get_teamlist(opcd[3,opcd.size]))
              o.create_assig(@client,@config,opcd[2])
              @sysbh.add_history(opcd[2])
          end
        when op.include?("new group") && opcd[0]=="new" && opcd[1]="group"
          if opcd.size==5 and @deep==ORGS and opcd[2]=="-f"
            t.new_group_file(@client,@config,opcd[3],opcd[4])
          end
          if opcd.size>3 and @deep==ORGS and !op.include?("-f")
             t.new_group(@client,@config,opcd[2],opcd[3..opcd.size-1])
          end

        when op.include?("rm team") && opcd[0]=="rm" && opcd[1]="team"            ##rm parse
          if opcd.size==3
            @teamlist=t.read_teamlist(@client,@config)
            if @teamlist[opcd[2]]!=nil
              t.delete_team(@client,@teamlist[opcd[2]])
              @sysbh.quit_history(@teamlist[opcd[2]])
              @teamlist=t.read_teamlist(@client,@config)
              @sysbh.add_history_str(1,@teamlist)
            else
              puts "Team not found"
            end
          end

        when op.include?("rm group") && opcd[0]=="rm" && opcd[1]="group"
          if opcd.size==3 and @deep==ORGS
            t.delete_group(@config,opcd[2])
          end
          if opcd.size==3 and @deep==ASSIG
            if opcd[2]!="-all"
              o.rm_assigment_group(@config,@config["Assig"],opcd[2],1)
            else
              o.rm_assigment_group(@config,@config["Assig"],opcd[2],2)
            end
          end
        when op.include?("rm student") && opcd[0]=="rm" && opcd[1]="student"
          if opcd.size==3 and @deep==ASSIG
            if opcd[2]!="-all"
              o.rm_assigment_student(@config,@config["Assig"],opcd[2],1)
            else
              o.rm_assigment_student(@config,@config["Assig"],opcd[2],2)
            end
          end
        when op.include?("rm repository") && opcd[0]=="rm" && opcd[1]="repository"
          if @deep==ORGS || @deep==USER || @deep==TEAM
            r.delete_repository(@client,@config,opcd[2],@deep)
            if @deep==ORGS
              @orgs_repos.delete(opcd[2])
            end
          end
        when op.include?("rm repo")&& opcd[0]=="rm" && opcd[1]="repo"
          if @deep==ASSIG and opcd.size==3
            o.rm_assigment_repo(@config,@config["Assig"],opcd[2])
          end
        when op == "info"
          if @deep==ASSIG then o.show_assig_info(@config,@config["Assig"]) end
          if @deep==USER_REPO || @deep==TEAM_REPO || @deep==ORGS_REPO then r.info_repository(@client,@config,@deep) end
        when op== "add repo"
          if @deep==ASSIG then o.add_repo_to_assig(@client,@config,@config["Assig"],nil) end
        when op.include?("change repo") && opcd[0]=="change" && opcd[1]=="repo"
          if @deep==ASSIG
            if opcd.size>2
              o.add_repo_to_assig(@client,@config,@config["Assig"],opcd[2])
            else
              o.add_repo_to_assig(@client,@config,@config["Assig"],1)
            end
          end
        when op.include?("change sufix") && opcd[0]=="change" && opcd[1]=="sufix"
          if @deep==ASSIG
            if opcd.size>2 then o.change_repo_sufix(@config,@config["Assig"],opcd[2]) end
          end
        when op=="add students" && @deep==ASSIG
           o.add_people_to_assig(@client,@config,@config["Assig"])
        when op.include?("rm")
          if @deep==ORGS and opcd[1]=="people" and opcd[2]=="info"
            o.rm_people_info(@client,@config)
          end
        when op== "add group"
            if @deep=ASSIG then o.add_group_to_assig(@client,@config,@config["Assig"]) end
        when op == "version"
          puts "GitHub Education Shell v#{Ghedsh::VERSION}"

        when op.include?("add team member") && opcd[0]=="add" && opcd[1]="team" && opcd[2]="member"
          if opcd.size==4 and @deep==TEAM
            t.add_to_team(@client,@config,opcd[3])
          end

        when op.include?("close issue") && opcd[0]=="close" && opcd[1]="issue"
          if (@deep==ORGS_REPO || @deep==USER_REPO || @deep==TEAM_REPO) and opcd.size==3
            r.close_issue(@client,@config,@deep,opcd[2])
          end

        when op.include?("open issue") && opcd[0]=="open" && opcd[1]="issue"
          if (@deep==ORGS_REPO || @deep==USER_REPO || @deep==TEAM_REPO) and opcd.size==3
            r.open_issue(@client,@config,@deep,opcd[2])
          end

        when op == "assignments"
          if @deep==ORGS
            o.show_assignments(@client,@config)
            @sysbh.add_history_str(2,o.get_assigs(@client,@config,false))
          end
        when op =="make"
          if @deep==ASSIG
            o.make_assig(@client,@config,@config["Assig"])
          end
        when op.include?("open") && opcd[0]=="open"
          if @deep==USER_REPO || @deep==TEAM_REPO || @deep==ORGS_REPO then r.open_repository(@client,@config,@deep) end
          if @deep==USER then u.open_user(@client) end
          if @deep==ORGS
            if opcd.size==1
              o.open_org(@client,@config)
            else
              if opcd.size==2
                o.open_user_url(@client,@config,opcd[1],nil)
              else
                o.open_user_url(@client,@config,opcd[1],opcd[2])
              end
            end
          end
          if @deep==TEAM then t.open_team_repos(@config) end
          if @deep==ASSIG then o.open_assig(@config,@config["Assig"]) end
      end

      if opcd[0]=="issue" and opcd.size>1
        if @deep==ORGS_REPO || @deep==USER_REPO || @deep==TEAM_REPO
          r.show_issue(@client,@config,@deep,opcd[1])
        end
      end

      if opcd[0]=="cd" and opcd[1]!=".."
        if opcd[1]=="/" or opcd.size==1
          self.cdback(true)
        else
          if opcd[1]=="repo" and opcd.size>2
            self.set(opcd[2])
          else
            if opcd[1].include?("/")
              cdlist=opcd[1].split("/")
              cdlist.each do |i|
                opscript.push("cd #{i}")
              end
            else
              self.cd(opcd[1])
            end
          end
        end
      end
      if opcd[0]=="do" and opcd.size>1
        opscript=s.load_script(opcd[1])
      end
      if opcd[0]=="set"
        self.set(opcd[1])
      end
      if opcd[0]=="repos" and opcd.size==1
        self.repos(false)
      end
      if opcd[0]=="repos" and opcd.size>1         ##Busca con expresion regular, si no esta en la cache realiza la consulta
        if opcd[1]=="-all" || opcd[1]=="-a"
          self.repos(true)
        else
          case
          when @deep==USER
            if @repos_list.empty?
              r.show_repos(@client,@config,@deep,opcd[1])
              @repos_list=r.get_repos_list(@client,@config,@deep)
            else
              @sysbh.showcachelist(@repos_list,opcd[1])
            end
          when @deep==ORGS
            if @orgs_repos.empty?
              r.show_repos(@client,@config,@deep,opcd[1])
              @orgs_repos=r.get_repos_list(@client,@config,@deep)
            else
              @sysbh.showcachelist(@orgs_repos,opcd[1])
            end
          when @deep==TEAM
            if @teams_repos.empty?
              r.show_repos(@client,@config,@deep,opcd[1])
              @teams_repos=r.get_repos_list(@client,@config,@deep)
            else
              @sysbh.showcachelist(@teams_repos,opcd[1])
            end
          end
        end
      end

      if opcd[0]=="private" and opcd.size==2
        if opcd[1]=="true" || opcd[1]=="false"
          r.edit_repository(@client,@config,@deep,opcd[1])
        end
      end

      if opcd[0]=="people" and opcd[1]=="info"
        if opcd.size==2
          info_strm=o.show_people_info(@client,@config,nil)
          if info_strm!=nil then @sysbh.add_history_str(2,info_strm) end
        else
          if opcd[2].include?("/")
            o.search_rexp_people_info(@client,@config,opcd[2])
          else
            o.show_people_info(@client,@config,opcd[2])
          end
        end
      end
      if opcd[0]=="clone"
        if opcd.size==2
          r.clone_repo(@client,@config,opcd[1],@deep)
        end
        if opcd.size==1 && (@deep==USER_REPO || @deep==TEAM_REPO || @deep==ORGS_REPO)
          r.clone_repo(@client,@config,nil,@deep)
        end
      end
      if op.match(/^!/)
        op=op.split("!")
        s.execute_bash(op[1])
      end
      if opcd[0]=="clone" and opcd.size>2
          #r.clone_repo(@client,@config,opcd[1])
      end
      if opcd[0]=="files"
        if opcd.size==1
          r.get_files(@client,@config,@repo_path,true,@deep)
        else
          r.get_files(@client,@config,opcd[1],true,@deep)
        end
      end
      if opcd[0]=="cat" and opcd.size>1
        r.cat_file(@client,@config,opcd[1],@deep)
      end
    end

  end

end
