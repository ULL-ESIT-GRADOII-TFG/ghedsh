#!/usr/bin/env ruby
require 'require_all'
require 'json'
require 'readline'
require 'octokit'

require 'actions/help'
require 'actions/orgs'
require 'actions/repo'
require 'actions/system'
require 'actions/teams'
require 'actions/user'

class Interface
  attr_reader :option
  attr_accessor :config
  attr_accessor :client
  attr_accessor :deep
  attr_accessor :memory
  attr_accessor :teamlist
  LIST = ['repos', 'exit', 'orgs','help', 'members','teams', 'cd ', 'commits','forks', 'add_team_member ','create_team ','delete_team ','create_repository '].sort

  def initialize
    self.run
    @sysbh=Sys.new()
  end

  #loading from config file

  def load_config
    @config=Sys.new.load_config()
    if @config["User"] == nil
      return false
    else
      @deep=1
      return true
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
    case
      when @deep == 1
        HelpM.new.user()
      when @deep == 2
        HelpM.new.org()
      when @deep == 3
        HelpM.new.org_repo()
      when @deep == 10
        HelpM.new.user_repo()
      when @deep == 4
        HelpM.new.orgs_teams()
    end
  end


  def get_data
    puts @config
  end

  def cdback()
    case
      #when @deep == 1 then @config["User"]=nil
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
      @config["Org"]=path

      @temlist=Hash.new
      @teamlist=Teams.new.read_teamlist(@client,@config)
      self.add_history_str(1,@teamlist)
      @deep=2
    when @deep == 2
      @config["Team"]=path
      @config["TeamID"]=@teamlist[path]
      @deep=4
      #self.get_data
    end
  end

  #set the repo
  def set(path)
    case
    when @deep==1
      @config["Repo"]=path
      @deep=10
    when @deep==2
      @config["Repo"]=path
      @deep=3
    when @deep==4
      @config["Repo"]=path
      @deep=5
    end
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

  def run
    ex=1
    @memory=[]
    history=LIST+memory
    comp = proc { |s| LIST.grep( /^#{Regexp.escape(s)}/ ) }

    Readline.completion_append_character = ""
    Readline.completion_proc = comp
    HelpM.new.welcome()
    t=Teams.new
    r=Repositories.new

    if self.load_config == true
      self.load_config
      @client=Sys.new.login(@config["Token"])
      self.add_history_str(2,Organizations.new.read_orgs(@client))

      while ex != 0
        op=Readline.readline(self.prompt,true)
        opcd=op.split
        case
          when op == "exit" then ex=0
          when op == "help" then self.help()
          when op == "repos" then self.repos()
          #when op == "ls -l" then self.lsl()
          when op == "orgs" then self.orgs()
          when op == "cd .." then self.cdback()
          when op == "members" then self.members()
          when op == "teams" #then self.teams()
      	    if @deep==2
      	      Teams.new.show_teams_bs(@client,@config)
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
          case
          when @deep==1
            r.create_repository(@client,@config,opcd[1],1)
          when @deep==2
            r.create_repository(@client,@config,opcd[1],2)
          when @deep==4
            r.create_repository(@client,@config,opcd[1],4)
          end
        end
      end
    else
      Sys.new.set_loguin_data_sh()
    end

    Sys.new.save_config(@config)
  end

end
