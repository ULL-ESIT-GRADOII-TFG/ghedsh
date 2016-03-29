require 'readline'
require 'octokit'
require 'json'
require 'require_all'
require_rel '.'

class Sys

  def load_config
    json = File.read('./lib/configure/configure.json')
    config=JSON.parse(json)

    if config["User"] == nil
      return false
    else
      return config
    end
  end

  def load_assig_db
    json = File.read('./lib/db/assignments.json')
    config=JSON.parse(json)
    if config["Orgs"] == nil
      return false
    else
      return config
    end
  end

  def save_config(data)
    File.write('./lib/configure/configure.json', data.to_json)
  end

  def save_db(data)
    File.write('./lib/db/assignments.json', data.to_json)
  end

  def get_config
  end

  def login(username,password,token)
    user=Octokit::Client.new(:access_token =>token)
    if user==false
      puts "Oauth error"
    else
      return user
    end
  end

  def set_loguin_data_sh
    puts "User: "
    user = gets.chomp
    puts "Pass: "
    pass = gets.chomp
    puts "Token: "
    token = gets.chomp
  end

end
