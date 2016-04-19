require 'readline'
require 'fileutils'
require 'octokit'
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

  def save_token(path,token)
    File.write("#{path}/ghedsh-token",token)
  end

  def login(token)
    user=Octokit::Client.new(:access_token =>token)
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
    if us!=nil
      puts "Login succesful as #{us.login}\n"
      config["User"]=us.login
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
    FileUtils.mkdir_p(configure_path)
    File.new("#{configure_path}/ghedsh-token","w")
    File.write("#{configure_path}/ghedsh-cache.json",con.to_json)
    puts "Confiration files created in #{configure_path}"
  end


  def save_cache(path,data)
    File.write('./.ghedsh/ghedsh-cache.json',data.to_json)
  end

  def save_db(path,data)
    File.write("#{path}/db/assignments.json", data.to_json)
  end

  def execute_bash(exp)
    system(exp)
  end

  def search_rexp(list,exp)
    list= list.select{|o| o.match(/#{exp}/)}
    #puts list
    return list
  end

end
