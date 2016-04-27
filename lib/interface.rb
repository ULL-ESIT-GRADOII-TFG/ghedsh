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
  attr_reader :option
  attr_accessor :config
  attr_accessor :client
  attr_accessor :deep
  attr_accessor :memory
  attr_reader :teamlist
  attr_reader :orgs_list
  LIST = ['repos', 'exit', 'orgs','help', 'members','teams', 'cd ', 'commits','forks', 'add_team_member ','create_team ','delete_team ','create_repository ','clone_repo '].sort

  def initialize
    sysbh=Sys.new()
    options=sysbh.parse

    if options[:user]==nil && options[:token]==nil &&  options[:path]!=nil
      self.run(options[:path],options[:token],options[:user])
    else
      self.run("#{ENV['HOME']}/.ghedsh",options[:token],options[:user])
    end
  end

  def add_history(value)
    @memory.push(value)
    self.write_memory
  end

  def quit_history(value)
    @memory.pop(value)
    self.write_memory
  end

  def add_history_str(mode,value)
    if mode==1
      value.each do |i|
        @memory.push(i[0])
        self.write_memory
      end
    end
    if mode==2
      value.each do |i|
        @memory.push(i)
        self.write_memory
      end
    end
  end


  def write_memory
    history=(LIST+@memory).sort
    comp = proc { |s| history.grep( /^#{Regexp.escape(s)}/ ) }
    Readline.completion_append_character = ""
    Readline.completion_proc = comp
  end


  def prompt()
    case
      when @deep == 1 then return @config["User"]+"> "
      when @deep == 10 then return @config["User"]+">"+@config["Repo"]+"> "
      when @deep == 2 then return @config["User"]+">"+@config["Org"]+"> "
      when @deep == 4 then return @config["User"]+">"+@config["Org"]+">"+@config["Team"]+"> "
      when @deep == 5 then return @config["User"]+">"+@config["Org"]+">"+@config["Team"]+">"+@config["Repo"]+"> "
      when @deep == 3 then return @config["User"]+">"+@config["Org"]+">"+@config["Repo"]+"> "
    end
  end

  def help()
    h=HelpM.new()
    case
      when @deep == 1
        h.user()
      when @deep == 2
        h.org()
      when @deep == 3
        h.org_repo()
      when @deep == 10
        h.user_repo()
      when @deep == 4
        h.orgs_teams()
    end
  end

  def cdback()
    case
      when @deep == 2
        @config["Org"]=nil
        @deep=1
      when @deep == 3
        @config["Repo"]=nil
        @deep=2
      when @deep == 10
        @config["Repo"]=nil
        @deep=1
      when @deep == 4
        @config["Team"]=nil
        @config["TeamID"]=nil
        @deep=2
    end
  end

  def cd(path)
    case
    when @deep==1
      @orgs_list=Organizations.new.read_orgs(@client)
      aux=@orgs_list
      if aux.one?{|aux| aux==path}
        @config["Org"]=path
        @teamlist=Teams.new.read_teamlist(@client,@config)
        self.add_history_str(1,@teamlist)
        @deep=2
      else
        puts "No organization is available with that name"
      end
    when @deep == 2
      aux=@teamlist
      if aux[path]!=nil
        @config["Team"]=path
        @config["TeamID"]=@teamlist[path]
        @deep=4
      else
        puts "No team is available with that name"
      end
    end
  end

  #set the repo
  def set(path)
    reposlist=Repositories.new()
    case
    when @deep==1
      @config["Repo"]=path
      if reposlist.get_repos_list(@client,@config,@deep).one?{|aux| aux==path}
        @deep=10
      end
    when @deep==2
      @config["Repo"]=path
      if reposlist.get_repos_list(@client,@config,@deep).one?{|aux| aux==path}
        @deep=3
      end
    when @deep==4
      @config["Repo"]=path
      if reposlist.get_repos_list(@client,@config,@deep).one?{|aux| aux==path}
        @deep=5
      end
    end
    if @deep==1 || @deep==2 || @deep==4 then puts "No repository is available with that name" end
  end

  def orgs()
    case
    when @deep==1
      self.add_history_str(2,Organizations.new.show_orgs(@client,@config))
    end
  end

  def members()
    case
    when @deep==2
      self.add_history_str(2,Organizations.new.show_organization_members_bs(@client,@config))
    when @deep==4
      self.add_history_str(2,Teams.new.show_team_members_bs(@client,@config))
    end
  end

  def repos()
    repo=Repositories.new()
    case
      when @deep == 1
        list=repo.show_repos(@client,@config,1)
        self.add_history_str(2,list)
      when @deep ==2
        list=repo.show_repos(@client,@config,2)
        self.add_history_str(2,list)
      when @deep==4
        list=repo.show_repos(@client,@config,3)
        self.add_history_str(2,list)
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
    case
    when @deep==3
      c.show_commits(@client,@config,1)
    when @deep==10
      c.show_commits(@client,@config,2)
    end
    print "\n"
  end

  def show_forks()
    case
    when @deep==3
      Repositories.new.show_forks(@client,@config,1)
    end
  end

  def collaborators()
    case
    when @deep==3
      Repositories.show_collaborators(@client,@config,1)
    end
  end

  def run(config_path, argv_token,user)
    ex=1
    @memory=[]
    history=LIST+memory
    comp = proc { |s| LIST.grep( /^#{Regexp.escape(s)}/ ) }

    Readline.completion_append_character = ""
    Readline.completion_proc = comp
    HelpM.new.welcome()

    t=Teams.new
    r=Repositories.new
    s=Sys.new
    # orden de búsqueda: ~/.ghedsh.json ./ghedsh.json ENV["ghedsh"] --configpath path/to/file.json

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

    @deep=1
    if @client!=nil
      self.add_history_str(2,Organizations.new.read_orgs(@client))
    end

    while ex != 0
      op=Readline.readline(self.prompt,true)
      opcd=op.split
      case
        when op == "exit" then ex=0
          s.save_cache(config_path,@config)
        when op == "help" then self.help()
        when op == "orgs" then self.orgs()
        when op == "cd .." then self.cdback()
        when op == "members" then self.members()
        when op == "teams" #then self.teams()
      	  if @deep==2
      	    t.show_teams_bs(@client,@config)
      	  end
        when op == "commits" then self.commits()
        when op == "col" then self.collaborators()
        when op == "forks" then self.show_forks()
      end

      if opcd[0]=="cd" and opcd[1]!=".."
        self.cd(opcd[1])
        #else
        #  self.cdback()
      end
      if opcd[0]=="set"
        self.set(opcd[1])
      end
      if opcd[0]=="repos" and opcd.size==1
        self.repos()
      end
      if opcd[0]=="repos" and opcd.size>1
        case
          when @deep==1
            r.show_repos_smart(@client,@config,opcd[1],1)
          when @deep==2
            r.show_repos_smart(@client,@config,opcd[1],2)
          when @deep==3
            r.show_repos_smart(@client,@config,opcd[1],3)
        end
      end
      if opcd[0]=="add_team_member"
        t.add_to_team(@client,@config,opcd[1])
      end
      if opcd[0]=="create_team" and opcd.size==2
      	t.create_team(@client,@config,opcd[1])
      	@teamlist=t.read_teamlist(@client,@config)
      	self.add_history_str(1,@teamlist)
      end
      if opcd[0]=="delete_team"
        t.delete_team(@client,@teamlist[opcd[1]])
        self.quit_history(@teamlist[opcd[1]])
        @teamlist=t.read_teamlist(@client,@config)
        self.add_history_str(1,@teamlist)
      end
      if opcd[0]=="create_team" and opcd.size>2
      	t.create_team_with_members(@client,@config,opcd[1],opcd[2..opcd.size])
      	@teamlist=t.read_teamlist(@client,@config)
      	self.add_history_str(1,@teamlist)
      end
      if opcd[0]=="create_repository" and opcd.size==2
        r.create_repository(@client,@config,opcd[1],@deep)
      end
      if opcd[0]=="create_repository" and opcd.size>2
        case
        when @deep==2
          r.create_repository_by_teamlist(@client,@config,opcd[1],opcd[2,opcd.size],self.get_teamlist(opcd[2,opcd.size]))
        end
      end

      if opcd[0]=="clone_repo" and opcd.size==2
        r.clone_repo(@client,@config,opcd[1],@deep)
      end
      if op.match(/^!/)
        op=op.split("!")
        s.execute_bash(op[1])
      end
      if opcd[0]=="clone_repo" and opcd.size>2
          #r.clone_repo(@client,@config,opcd[1])
      end
    end

  end

end
