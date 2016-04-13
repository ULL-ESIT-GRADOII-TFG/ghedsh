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
      configure_path="#{ENV['GEM_HOME']}/gems/ghedsh-#{Ghedsh::VERSION}/lib/configure/configure.json"
      if (File.exist?(configure_path))==false
        self.create_config(configure_path)
      end
      load_config(configure_path)
    end
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
      puts "Login succesful as #{us.login}"
      config["User"]=us.login
      config["Token"]=token
      return config
    end
  end

  def load_assig_db
    path='./lib/db/assignments.json'
    if (File.exist?(path))==true
      json = File.read(path)
    else
      path="#{ENV['GEM_HOME']}/gems/ghedsh-#{Ghedsh::VERSION}/lib/db/assignments.json"
      json = File.read(path)
    end
      config=JSON.parse(json)
      return config
  end

  def create_config(path)
      con={:User=>nil,:Token=>nil,:Org=>nil,:Repo=>nil,:Team=>nil,:TeamID=>nil}
      File.write(path,con.to_json)
  end

  def save_config(data)
    if (File.exist?('./lib/configure/configure.json'))==true
      File.write('./lib/configure/configure.json', data.to_json)
    else
      File.write("#{ENV['GEM_HOME']}/gems/ghedsh-#{Ghedsh::VERSION}/lib/configure/configure.json", data.to_json)
    end
  end

  def save_db(data)
    if (File.exist?('./lib/db/assignments.json'))==true
      File.write('./lib/db/assignments.json', data.to_json)
    else
      File.write("#{ENV['GEM_HOME']}/gems/ghedsh-#{Ghedsh::VERSION}/lib/db/assignments.json", data.to_json)
    end
  end

  def get_config
    #todo
  end


  def search_rexp(list,exp)
    list= list.select{|o| o.match(/#{exp}/)}
    #puts list
    return list
  end

end
