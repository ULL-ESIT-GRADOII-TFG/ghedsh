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
TEAM_REPO=5

class Interface
  attr_reader :option, :sysbh
  attr_accessor :config
  attr_accessor :client
  attr_accessor :deep
  attr_accessor :memory
  attr_reader :orgs_list,:repos_list, :teamlist, :orgs_repos, :teams_repos

  def initialize
    @sysbh=Sys.new()
    @repos_list=[]; @orgs_repos=[]; @teams_repos=[]

    options=@sysbh.parse

    trap("SIGINT") { throw :ctrl_c }
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
      when @deep == USER_REPO then return @config["User"]+">"+ "\e[31m#{@config["Repo"]}\e[0m"+"> "
      when @deep == ORGS then return @config["User"]+">"+ "\e[34m#{@config["Org"]}\e[0m"+"> "
      when @deep == TEAM then return @config["User"]+">"+"\e[34m#{@config["Org"]}\e[0m"+">"+@config["Team"]+"> "
      when @deep == TEAM_REPO then return @config["User"]+">"+"\e[34m#{@config["Org"]}\e[0m"+">"+@config["Team"]+">"+"\e[31m#{@config["Repo"]}\e[0m"+"> "
      when @deep == ORGS_REPO then return @config["User"]+">"+"\e[34m#{@config["Org"]}\e[0m"+">"+"\e[31m#{@config["Repo"]}\e[0m"+"> "
    end
  end

  def help()
    h=HelpM.new()
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
          @config["Repo"]=nil
          @deep=2
        when @deep == USER_REPO
          @config["Repo"]=nil
          @deep=1
        when @deep == TEAM
          @config["Team"]=nil
          @config["TeamID"]=nil
          @teams_repos=[]
          @deep=2
      end
    else
      @config["Org"]=nil
      @config["Repo"]=nil
      @config["Team"]=nil
      @config["TeamID"]=nil
      @deep=1
      @orgs_repos=[]; @teams_repos=[]
    end
  end

  #Go to the path, depends with the scope
  #if you are in user scope, first searchs Orgs then Repos, etc.
  def cd(path)
    case
    when @deep==USER
      @orgs_list=Organizations.new.read_orgs(@client)
      aux=@orgs_list
      if aux.one?{|aux| aux==path}
        @config["Org"]=path
        @teamlist=Teams.new.read_teamlist(@client,@config)
        @sysbh.add_history_str(1,@teamlist)
        @deep=2
      else
        puts "\nNo organization is available with that name"
        self.set(path)
      end
    when @deep == ORGS
      aux=@teamlist
      if aux[path]!=nil
        @config["Team"]=path
        @config["TeamID"]=@teamlist[path]
        @deep=TEAM
      else
        puts "\nNo team is available with that name"
        self.set(path)
      end
    when @deep == TEAM
      self.set(path)
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
      @config["Repo"]=path
      if @orgs_repos.empty? == false
        reposlist=@orgs_repos
      else
        reposlist=reposlist.get_repos_list(@client,@config,@deep)
      end
      if reposlist.one?{|aux| aux==path}
        @deep=ORGS_REPO
        puts "Set in #{@config["Org"]} repository: #{path}\n\n"
      end
    when @deep==TEAM
      @config["Repo"]=path
      if @teams_repos.empty? == false
        repostlist=@teams_repos
      else
        reposlist=reposlist.get_repos_list(@client,@config,@deep)
      end
      if reposlist.one?{|aux| aux==path}
        @deep=TEAM_REPO
        puts "Set in #{@config["Team"]} repository: #{path}\n\n"
      end
    end
    if @deep==USER || @deep==ORGS || @deep==TEAM then puts "No repository is available with that name\n\n" end
  end

  def orgs()
    case
    when @deep==USER
      @sysbh.add_history_str(2,Organizations.new.show_orgs(@client,@config))
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

  def repos()
    repo=Repositories.new()
    case
      when @deep == USER
        if @repos_list.empty?
          list=repo.show_repos(@client,@config,USER,nil)
          @sysbh.add_history_str(2,list)
          @repos_list=list
        else
          @sysbh.showcachelist(@repos_list,nil)
        end
      when @deep ==ORGS
        if @orgs_repos.empty?
          list=repo.show_repos(@client,@config,ORGS,nil)
          @sysbh.add_history_str(2,list)
          @orgs_repos=list
        else
          @sysbh.showcachelist(@orgs_repos,nil)
        end
      when @deep==TEAM
        if @teams_repos.empty?
          list=repo.show_repos(@client,@config,TEAM,nil)
          @sysbh.add_history_str(2,list)
          @teams_repos=list
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
    if @deep==ORGS_REPO || @deep==USER_REPO
      c.show_commits(@client,@config,@deep)
    end
    print "\n"
  end

  def show_forks()
    case
    when @deep==ORGS_REPO
      Repositories.new.show_forks(@client,@config,1)
    end
  end

  def collaborators()
    case
    when @deep==ORGS_REPO
      Repositories.show_collaborators(@client,@config,1)
    end
  end

  #Main program
  def run(config_path, argv_token,user)
    ex=1

    @sysbh.write_initial_memory()
    HelpM.new.welcome()

    t=Teams.new
    r=Repositories.new
    s=Sys.new
    # orden de búsqueda: ~/.ghedsh.json ./ghedsh.json ENV["ghedsh"] --configpath path/to/file.json

    #control de carga de parametros en el logueo de la aplicacion
    if user!=nil
      @config=s.load_config_user(config_path,user)
      @client=s.client
      if @config==nil
        ex=0
      end
    else
      @config=s.load_config(config_path,argv_token)
      @client=s.client
    end

    @deep=USER
    if @client!=nil
      @sysbh.add_history_str(2,Organizations.new.read_orgs(@client))
    end

    while ex != 0

      op=Readline.readline(self.prompt,true)
      opcd=op.split
      case
        when op == "exit" then ex=0
          s.save_cache(config_path,@config)
        when op == "help" then self.help()
        when op == "orgs" then self.orgs()
        when op == "cd .." then self.cdback(false)
        when op == "people" then self.people()
        when op == "teams" #then self.teams()
      	  if @deep==ORGS
      	    t.show_teams_bs(@client,@config)
      	  end
        when op == "commits" then self.commits()
        when op == "col" then self.collaborators()
        when op == "forks" then self.show_forks()
      end

      if opcd[0]=="cd" and opcd[1]!=".."
        if opcd[1]=="/"
          self.cdback(true)
        else
          if opcd[1]=="repo" and opcd.size>2
            self.set(opcd[2])
          else
            self.cd(opcd[1])
          end
        end
      end
      if opcd[0]=="set"
        self.set(opcd[1])
      end
      if opcd[0]=="repos" and opcd.size==1
        self.repos()
      end
      if opcd[0]=="repos" and opcd.size>1         ##Busca con expresion regular, si no esta en la cache realiza la consulta
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
      if opcd[0]=="add_team_member"
        t.add_to_team(@client,@config,opcd[1])
      end
      if opcd[0]=="new_team" and opcd.size==2
      	t.create_team(@client,@config,opcd[1])
      	@teamlist=t.read_teamlist(@client,@config)
      	@sysbh.add_history_str(1,@teamlist)
      end
      if opcd[0]=="rm_team"
        t.delete_team(@client,@teamlist[opcd[1]])
        self.quit_history(@teamlist[opcd[1]])
        @teamlist=t.read_teamlist(@client,@config)
        @sysbh.add_history_str(1,@teamlist)
      end
      if opcd[0]=="new_team" and opcd.size>2
      	t.create_team_with_members(@client,@config,opcd[1],opcd[2..opcd.size])
      	@teamlist=t.read_teamlist(@client,@config)
      	@sysbh.add_history_str(1,@teamlist)
      end
      if opcd[0]=="new_repository" and opcd.size==2
        r.create_repository(@client,@config,opcd[1],@deep)
      end
      if opcd[0]=="new_assignment" and opcd.size>2
        case
        when @deep==ORGS
          r.create_repository_by_teamlist(@client,@config,opcd[1],opcd[2,opcd.size],self.get_teamlist(opcd[2,opcd.size]))
        end
      end
      if opcd[0]=="clone" and opcd.size==2
        r.clone_repo(@client,@config,opcd[1],@deep)
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
          r.get_files(@client,@config,'',@deep)
        else
          r.get_files(@client,@config,opcd[1],@deep)
        end
      end
      if opcd[0]=="cat" and opcd.size>1
        r.cat_file(@client,@config,opcd[1],@deep)
      end
    end

  end

end
