require 'readline'
require 'octokit'
require 'json'
require 'actions/system'
require 'version'

class Sys

  def load_config(configure_path)
    if (File.exist?(configure_path))==true
      json = File.read(configure_path)
      config=JSON.parse(json)

      if config["User"] == nil
        return self.set_loguin_data_sh(config)
      else
        return config
      end
    else
      puts "nope"
      configure_path="#{ENV['GEM_HOME']}/gems/ghedsh-#{Ghedsh::VERSION}/lib/configure/configure.json"
      self.create_config(configure_path)
      load_config(configure_path)
    end
  end

  def load_assig_db
    json = File.read('./lib/db/assignments.json')
    config=JSON.parse(json)
    #if config["Orgs"] == nil
      #return false
    #else
      return config
    #end
  end

  def create_config(path)
      con={:User=>nil,:Token=>nil,:Org=>nil,:Repo=>nil,:Team=>nil,:TeamID=>nil}
      File.write(path,con.to_json)
  end

  def save_config(data)
    File.write('./lib/configure/configure.json', data.to_json)
  end

  def save_db(data)
    File.write('./lib/db/assignments.json', data.to_json)
  end

  def get_config
  end

  def login(token)
    user=Octokit::Client.new(:access_token =>token)
    if user==false
      puts "Oauth error"
    else
      return user
    end
  end

  def set_loguin_data_sh(config)
    puts "Insert you Access Token: "
    token = gets.chomp
    us=self.login(token)
    if us!=nil
      puts "Login succesful ",us.login
      config["User"]=us.login
      config["Token"]=token
      return config
    end
  end

  def search_rexp(list,exp)
    list= list.select{|o| o.match(/#{exp}/)}
    #puts list
    return list
  end

end
