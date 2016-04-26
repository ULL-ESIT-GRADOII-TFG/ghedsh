require 'readline'
require 'fileutils'
require 'octokit'
require 'optparse'
require 'json'
require 'actions/system'
require 'version'

class Sys
  attr_accessor :client

  def load_config(configure_path,argv_token)
    if File.exist?(configure_path)
      if argv_token==nil
        token=File.read("#{configure_path}/ghedsh-token")
      else
        token=argv_token
      end
      json = File.read("#{configure_path}/ghedsh-cache.json")
      config=JSON.parse(json)

      if token!=""
        @client=self.login(token)
        config["User"]=@client.login
        userslist=self.load_users(configure_path)

        if userslist["#{config["User"]}"]==nil
          userslist["#{config["User"]}"]=token
          self.save_users(configure_path,userslist)
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

  def load_config_user(configure_path, user)
    if File.exist?(configure_path)
      list=self.load_users(configure_path)
      if list["#{user}"]!=nil
        json = File.read("#{configure_path}/ghedsh-cache.json")
        config=JSON.parse(json)
        @client=self.login(list["#{user}"])
        config["User"]=@client.login
        self.save_token(configure_path,list["#{user}"])
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

  def save_token(path,token)
    File.write("#{path}/ghedsh-token",token)
  end

  def login(token)
    user=Octokit::Client.new(:access_token =>token) #per_page:100
    user.auto_paginate=true #show all pages of any query
    if user==false
      puts "Oauth error"
    else
      return user
    end
  end

  def set_loguin_data_sh(config,configure_path)
    puts "Insert you Access Token: "
    token = gets.chomp
    us=self.login(token)
    userhash=Hash.new

    if us!=nil
      puts "Login succesful as #{us.login}\n"
      config["User"]=us.login
      userhash["#{config["User"]}"]=token
      self.save_users(configure_path,userhash)
      File.write("#{configure_path}/ghedsh-token",token) #config["Token"]=token
      @client=us
      return config
    end
  end

  def load_assig_db(path)
    if (File.exist?(path))==true
      json = File.read("#{path}/db/assignments.json")
    else
      #path="/db/assignments.json"
      #json = File.read(path)
    end
      config=JSON.parse(json)
      return config
  end

  def create_config(configure_path)
    con={:User=>nil,:Org=>nil,:Repo=>nil,:Team=>nil,:TeamID=>nil}
    us={}
    FileUtils.mkdir_p(configure_path)
    File.new("#{configure_path}/ghedsh-token","w")
    File.write("#{configure_path}/ghedsh-cache.json",con.to_json)
    File.write("#{configure_path}/ghedsh-users.json",us.to_json)
    puts "Confiration files created in #{configure_path}"
  end


  def save_cache(path,data)
    File.write("#{path}/ghedsh-cache.json",data.to_json)
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
    #puts list
    return list
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
      puts "Argument error. Use ghedsh -v or ghedsh --help for more information about the usage of this program"
      exit
    end
    return options
  end

end
