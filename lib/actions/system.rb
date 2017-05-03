require 'readline'
require 'fileutils'
require 'octokit'
require 'optparse'
require 'json'
require 'actions/system'
require 'version'

class Sys
  attr_reader :client
  attr_reader :memory
  LIST = ['repos', 'exit', 'orgs','help', 'people','teams', 'cd ', 'cd repo ','commits','forks', 'add_team_member ','new team ','rm team ','new repository ','new assignment ','clone ', 'issues',
    'version', 'cat ', 'groups', 'files', 'assignments','new issue ', 'open issue', 'new ','open ', 'close issue', 'new group ', 'rm group', 'rm ', 'do ', 'info','make','add repo',
    'add group','rm repository ', 'new people info ', 'private ', 'people info ', 'new issue comment ', "rm people info", "change repo",'add students','new relation'].sort

  def initialize()
    @memory=[]
  end

  #                                 CACHE READLINE METHODS
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

  def load_memory(path,config)
    if File.exist?("#{path}/ghedsh-#{config["User"]}-history")
      source=File.read("#{path}/ghedsh-#{config["User"]}-history")
      s=source.split("\n")
      s.each do |i|
        Readline::HISTORY.push(i)
      end
    else
      File.write("#{path}/ghedsh-#{config["User"]}-history","")
    end
  end

  def save_memory(path,config)
    mem= Readline::HISTORY.to_a
    me=""
    mem.each do |i|
      me=me+i.to_s+"\n"
    end
    File.write("#{path}/ghedsh-#{config["User"]}-history",me)
  end


  def write_initial_memory
    history=LIST+memory
    comp = proc { |s| LIST.grep( /^#{Regexp.escape(s)}/ ) }

    Readline.completion_append_character = ""
    Readline.completion_proc = comp
  end
  #                                    END CACHE READLINE METHODS

  #Loading initial configure, if ghedsh path doesnt exist, call the create method
  def load_config(configure_path,argv_token)
    if File.exist?(configure_path)
      if argv_token==nil
        token=self.get_login_token(configure_path)
      else
        token=argv_token
      end
      json = File.read("#{configure_path}/ghedsh-cache.json")
      config=JSON.parse(json)

      if token!=nil
        @client=self.login(token)
        config["User"]=@client.login
        userslist=self.load_users(configure_path)

        if userslist["users"].detect {|f| f["#{config["User"]}"] }==nil
          self.add_users(configure_path,"#{config["User"]}"=>token)
        end
        if argv_token!=nil
          self.save_token(configure_path,argv_token)
        end
        return config
      else
        return self.set_loguin_data_sh(config,configure_path)
      end
    else
      self.create_config(configure_path)
      load_config(configure_path,argv_token)
    end
  end

  #loading configure with --user mode
  def load_config_user(configure_path, user)
    if File.exist?(configure_path)
      list=self.load_users(configure_path)
      userFound=list["users"].detect {|f| f["#{user}"]}
      if userFound!=nil
        self.clear_cache(configure_path)
        json = File.read("#{configure_path}/ghedsh-cache.json")
        config=JSON.parse(json)
        @client=self.login(userFound["#{user}"])
        config["User"]=@client.login
        self.save_token(configure_path,userFound["#{user}"])
        return config
      else
        puts "User not found"
        return nil
      end
    else
      puts "No user's history is available"
      return nil
    end
  end

  def load_users(path)
    json=File.read("#{path}/ghedsh-users.json")
    users=JSON.parse(json)
    return users
  end

  # USER=1
  # ORGS=2
  # USER_REPO=10
  # ORGS_REPO=3
  # TEAM=4
  # ASSIG=6
  # TEAM_REPO=5

  def return_deep(path)
    json = File.read("#{path}/ghedsh-cache.json")
    cache=JSON.parse(json)
    deep=1
    case
      when cache["Team"]!=nil
        if cache["Repo"]!=nil
          deep=5
        else
          deep=4
        end
      when cache["Team"]==nil
        if cache["Org"]!=nil
          if cache["Repo"]!=nil
            deep=3
          else
            if cache["Assig"]!=nil
              deep=6
            else
              deep=2
            end
          end
        else
          if cache["Repo"]!=nil
           deep=10
          else
            deep=1
          end
        end
    end
    return deep
   end

  def add_users(path,data)
    json=File.read("#{path}/ghedsh-users.json")
    users=JSON.parse(json)
    users["users"].push(data)
    File.write("#{path}/ghedsh-users.json",users.to_json)
  end

  def save_token(path,token)
    json=File.read("#{path}/ghedsh-users.json")
    login=JSON.parse(json)
    login["login"]=token
    File.write("#{path}/ghedsh-users.json",login.to_json)
  end

  def get_login_token(path)
    json=File.read("#{path}/ghedsh-users.json")
    us=JSON.parse(json)
    return us["login"]
  end

  def login(token)
    begin
      user=Octokit::Client.new(:access_token =>token) #per_page:100
      user.auto_paginate=true #show all pages of any query
    rescue
      puts "Oauth error"
    end
    return user
  end

  #initial program configure
  def set_loguin_data_sh(config,configure_path)
    puts "Insert you Access Token: "
    token = gets.chomp
    us=self.login(token)
    userhash=Hash.new

    if us!=nil
      puts "Login succesful as #{us.login}\n"
      config["User"]=us.login
      self.add_users(configure_path,"#{config["User"]}"=>token)
      self.save_token(configure_path,token)
      @client=us
      return config
    end
  end

  def load_assig_db(path)
    if (File.exist?(path))==true
      if File.exist?("#{path}/assignments.json")
        json = File.read("#{path}/assignments.json")
      else
        #{"Organization":[{"name":null,"assignments":[{"name":null,"teams":{"teamid":null}}]}]}
        con={:orgs=>[]}
        File.write("#{path}/assignments.json",con.to_json)
        json = File.read("#{path}/assignments.json")
      end
    end
    config=JSON.parse(json)
    return config
  end

  def load_people_db(path)
    if (File.exist?(path))==true
      if File.exist?("#{path}/ghedsh-people.json")
        json = File.read("#{path}/ghedsh-people.json")
      else
        con={:orgs=>[]}
        File.write("#{path}/ghedsh-people.json",con.to_json)
        json = File.read("#{path}/ghedsh-people.json")
      end
    end
    config=JSON.parse(json)
    return config
  end

  def load_script(path)
    if (File.exist?(path))==true
      script = File.read("#{path}")
      return script.split("\n")
    else
      puts "No script is found with that name"
      return []
    end
  end

  def load_groups(path)
    if (File.exist?(path))==true
      if File.exist?("#{path}/groups.json")
        json = File.read("#{path}/groups.json")
      else
        con={:orgs=>[]}
        File.write("#{path}/groups.json",con.to_json)
        json = File.read("#{path}/groups.json")
      end
    else
      #path="/db/assignments.json"
      #json = File.read(path)
    end
      config=JSON.parse(json)
      return config
  end

  def create_temp(path)
    if (File.exist?(path))==false
      FileUtils.mkdir_p(path)
    end
  end

  def remove_temp(path)
    if (File.exist?(path))==true
      system("rm -rf #{path}")
    end
  end

  def save_groups(path,data)
    File.write("#{path}/groups.json",data.to_json)
  end

  def save_assigs(path,data)
    File.write("#{path}/assignments.json",data.to_json)
  end

  def save_people(path,data)
    File.write("#{path}/ghedsh-people.json",data.to_json)
  end

  #creates all ghedsh local stuff
  def create_config(configure_path)
    con={:User=>nil,:Org=>nil,:Repo=>nil,:Team=>nil,:TeamID=>nil}
    us={:login=>nil, :users=>[]}
    FileUtils.mkdir_p(configure_path)
    File.write("#{configure_path}/ghedsh-cache.json",con.to_json)
    File.write("#{configure_path}/ghedsh-users.json",us.to_json)
    puts "Confiration files created in #{configure_path}"
  end


  def save_cache(path,data)
    File.write("#{path}/ghedsh-cache.json",data.to_json)
  end

  def clear_cache(path)
    con={:User=>nil,:Org=>nil,:Repo=>nil,:Team=>nil,:TeamID=>nil}
    File.write("#{path}/ghedsh-cache.json",con.to_json)
  end

  def save_db(path,data)
    File.write("#{path}/db/assignments.json", data.to_json)
  end

  def save_users(path,data)
    File.write("#{path}/ghedsh-users.json",data.to_json)
  end

  def execute_bash(exp)
    system(exp)
  end

  def search_rexp(list,exp)
    list= list.select{|o| o.match(/#{exp}/)}
    return list
  end

  def search_rexp_peoplehash(list,exp)
    found=[]
    yes=false
    list.each do |i|
      i.each do |j|
        if j[1].match(/#{exp}/)
          yes=true
        end
      end
      if yes==true
        found.push(i)
        yes=false
      end
    end
    return found
  end

  def parse()
    options = {:user => nil, :token => nil, :path => nil}

    parser = OptionParser.new do|opts|
    	opts.banner = "Usage: ghedsh [options]\nWith no options it runs with default configuration. Configuration files are being set in #{ENV['HOME']}/.ghedsh\n"
    	opts.on('-t', '--token token', 'Provides a github access token by argument.') do |token|
    		options[:token] = token;
    	end
      opts.on('-c', '--configpath path', 'Give your own path for GHEDSH configuration files') do |path|
        options[:configpath] = path;
      end
    	opts.on('-u', '--user user', 'Change your user from your users list') do |user|
    		options[:user] = user;
    	end
      opts.on('-v', '--version', 'Show the current version of GHEDSH') do
        puts "GitHub Education Shell v#{Ghedsh::VERSION}"
        exit
      end
    	opts.on('-h', '--help', 'Displays Help') do
    		puts opts
    		exit
    	end
    end

    begin
      parser.parse!
    rescue
      puts "Argument error. Use ghedsh -h or ghedsh --help for more information about the usage of this program"
      exit
    end
    return options
  end

  def createTempFile(data)
    tempfile="temp.txt"
    path="#{ENV['HOME']}/.ghedsh/#{tempfile}"
    File.write(path,data)
    return path
  end

  def showcachelist(list,exp)
    print "\n"
    rlist=[]
    options=Hash.new
    o=Organizations.new
    regex=false

    if exp!=nil
      if exp.match(/^\//)
        regex=true
        sp=exp.split('/')
        exp=Regexp.new(sp[1],sp[2])
      end
    end
    counter=0
    allpages=true

    list.each do |i|
      if regex==false
        if counter==100 && allpages==true
          op=Readline.readline("\nThere are more results. Show next repositories (press any key) or Show all repositories (press a): ",true)
          if op=="a"
            allpages=false
          end
          counter=0
        end
        puts i
        rlist.push(i)
        counter=counter+1
      else

      if i.match(exp)
          puts i
          rlist.push(i)
          counter=counter+1
        end
      end
    end

    if rlist.empty?
      puts "No repository matches with that expression"
    else
      print "\n"
      puts "Repositories found: #{rlist.size}"
    end
  end

  def loadfile(path)
    if File.exist?(path)
      mem=File.read(path)
      mem=mem.split("\n")
      return mem
    else
      puts "File not found"
      return nil
    end
  end

  def open_url(url)
    case
    when RUBY_PLATFORM.downcase.include?("darwin")
      system("open #{url}")
    when RUBY_PLATFORM.downcase.include?("linux")
      system("xdg-open #{url}")
    end
  end
end
