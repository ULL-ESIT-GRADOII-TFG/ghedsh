require 'require_all'
require 'json'
require_rel '.'
require 'readline'
require 'octokit'


class Interface
  attr_reader :option
  attr_accessor :config
  attr_accessor :client
  attr_accessor :deep
  attr_accessor :memory
  attr_accessor :teamlist
  LIST = ['repos', 'exit', 'orgs','help', 'members','teams', 'cd ', 'commits','forks'].sort

  def initialize
  end


  def load_config
    json = File.read('./lib/configure/configure.json')
    config=JSON.parse(json)

    if config["User"] == nil
      return false
    else
      @config=config
      @deep=1
      return true
    end
  end

  def add_history(value)
    @memory.push(value)
    self.write_memory
  end

  def write_memory
    history=(LIST+@memory).sort
    comp = proc { |s| history.grep( /^#{Regexp.escape(s)}/ ) }
    Readline.completion_append_character = ""
    Readline.completion_proc = comp
  end

  def login(username,password,token)
    @client = Octokit::Client.new(:login=>username, :password=>password, :token =>token)

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
    end
  end

  def ls()
    case
      when @deep == 1
        print "\n"
        repo=@client.repositories
        repo.each do |i|
          puts i.name
          self.add_history(i.name)
        end
      when @deep ==2
        #puts @config["Org"]
        print "\n"
        repos=@client.organization_repositories(@config["Org"])
        repos.each do |y|
          puts y.name
          self.add_history(y.name)
        end
    end
    print "\n"
  end

  def lsl()

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
        @deep=2
    end
  end

  def cd(path)
    case
    when @deep==1
      @config["Org"]=path
      @deep=2
    when @deep == 2
      @config["Team"]=path
      puts @teamlist[path]
      @confing[:TeamID]=@teamlist[path]
      @deep=4
    end
  end

  def orgs()
    case
    when @deep==1
      print "\n"
      org=@client.organizations
      org.each do |i|
        o=eval(i.inspect)
        puts o[:login]
        self.add_history(o[:login])
      end
    end
    print "\n"
  end

  def members()
    case
    when @deep==2
      print "\n"
      mem=@client.organization_members(@config["Org"])
      mem.each do |i|
        m=eval(i.inspect)
        puts m[:login]
      end
    when @deep==4
      print "\n"
      mem=@client.team_members(@config["TeamID"])
      mem.each do |i|
        #m=eval(i.inspect)
        #puts m[:login]
      end
    end
    print "\n"
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

  def commits()
    print "\n"
    case
    when @deep==3
      mem=@client.commits(@config["Org"]+"/"+@config["Repo"],"master")
      mem.each do |i|
        #puts i.inspect
        print i[:sha],"\n",i[:commit][:author][:name],"\n",i[:commit][:author][:date],"\n",i[:commit][:message],"\n\n"
        #m=eval(i.inspect)
      end
    when @deep==10
      mem=@client.commits(@config["User"]+"/"+@config["Repo"],"master")
        mem.each do |i|
        print i[:sha],"\n",i[:commit][:author][:name],"\n",i[:commit][:author][:date],"\n",i[:commit][:message],"\n\n"
      end
    end
    print "\n"
  end

  def show_forks()
    print "\n"
    case
    when @deep==3
      mem=@client.forks(@config["Org"]+"/"+@config["Repo"])
      mem.each do |i|
        puts i[:owner][:login]
      end
    end
    print "\n"
  end

  def collaborators()
    print "\n"
    case
    when @deep==3
      mem=@client.collaborators(@config["Org"]+"/"+@config["Repo"])
      mem.each do |i|
        #puts i.name
        puts i[:author][:login]
        #m=eval(i.inspect)
      end
    end
    print "\n"
  end

  def teams()
    @teamlist=Hash.new
    case
    when @deep==2
      print "\n"
      mem=@client.organization_teams(@config["Org"])
      mem.each do |i|
        puts i.name
        @teamlist[i.name]=i[:id]
        #print "ID de equipo: ",i[:id],"\n"
      end
    end
    print "\n"
  end

  def run
    ex=1
    @memory=[]
    history=LIST+memory
    comp = proc { |s| LIST.grep( /^#{Regexp.escape(s)}/ ) }

    Readline.completion_append_character = ""
    Readline.completion_proc = comp
    HelpM.new.welcome()

    if self.load_config == true
      self.login(@config["User"],@config["Pass"], @config["Token"])

      while ex != 0
        op=Readline.readline(self.prompt,true)
        opcd=op.split
        case
          when op == "exit" then ex=0
          when op == "help" then self.help()
          when op == "repos" then self.ls()
          when op == "ls -l" then self.lsl()
          when op == "orgs" then self.orgs()
          when op == "cd .." then self.cdback()
          when op == "members" then self.members()
          when op == "teams" then self.teams()
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
      end
    else
      puts "User: "
      user = gets.chomp
      puts "Pass: "
      pass = gets.chomp
      puts "Token: "
      token = gets.chomp
      self.login(user,pass,token)
    end

    File.write('./lib/configure/configure.json',@config.to_json)
  end

end

inp = Interface.new
inp.load_config
inp.run
