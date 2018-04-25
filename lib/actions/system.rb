require 'readline'
require 'fileutils'
require 'octokit'
require 'tty-prompt'
require 'optparse'
require 'json'
require 'actions/system'
require 'version'
require 'common'

class Sys
  attr_reader :client
  attr_reader :memory
  LIST = %w[clear exit repos new_repo new_team rm_team rm_repo clone rm_cloned commits orgs people teams cd open bash].sort

  def initialize
    @memory = []
  end

  #                                 CACHE READLINE METHODS
  def add_history(value)
    @memory.push(value)
    write_memory
  end

  def quit_history(value)
    @memory.pop(value)
    write_memory
  end

  def add_history_str(mode, value)
    if mode == 1
      value.each do |i|
        @memory.push(i[0])
        write_memory
      end
    end
    if mode == 2
      value.each do |i|
        @memory.push(i)
        write_memory
      end
    end
  end

  def write_memory
    history = (LIST + @memory).sort
    comp = proc { |s| history.grep(/^#{Regexp.escape(s)}/) }
    Readline.completion_append_character = ''
    Readline.completion_proc = comp
  end

  def load_memory(path, config)
    if File.exist?("#{path}/ghedsh-#{config['User']}-history")
      source = File.read("#{path}/ghedsh-#{config['User']}-history")
      s = source.split("\n")
      s.each do |i|
        Readline::HISTORY.push(i)
      end
    else
      File.write("#{path}/ghedsh-#{config['User']}-history", '')
    end
  end

  def save_memory(path, config)
    mem = Readline::HISTORY.to_a
    me = ''
    mem.each do |i|
      me = me + i.to_s + "\n"
    end
    File.write("#{path}/ghedsh-#{config['User']}-history", me)
  end

  def write_initial_memory
    history = LIST + memory
    comp = proc { |s| LIST.grep(/^#{Regexp.escape(s)}/) }
    Readline.completion_append_character = ''
    Readline.completion_proc = comp
  end
  #                                    END CACHE READLINE METHODS

  # Loading initial configure, if ghedsh path doesnt exist, call the create method
  def load_config(configure_path, argv_token)
    if File.exist?(configure_path)
      token = if argv_token.nil?
                get_login_token(configure_path)
              else
                argv_token
              end
      json = File.read("#{configure_path}/ghedsh-cache.json")
      config = JSON.parse(json)

      if !token.nil?
        @client = login(token)
        config['User'] = @client.login
        config['user_url'] = @client.web_endpoint.to_s << @client.login.to_s
        userslist = load_users(configure_path)

        if userslist['users'].detect { |f| f[(config['User']).to_s] }.nil?
          add_users(configure_path, (config['User']).to_s => token)
        end
        save_token(configure_path, argv_token) unless argv_token.nil?
        return config
      else
        return set_loguin_data_sh(config, configure_path)
      end
    else
      create_config(configure_path)
      load_config(configure_path, argv_token)
    end
  end

  # loading configure with --user mode
  def load_config_user(configure_path, user)
    if File.exist?(configure_path)
      list = load_users(configure_path)
      userFound = list['users'].detect { |f| f[user.to_s] }
      if !userFound.nil?
        clear_cache(configure_path)
        json = File.read("#{configure_path}/ghedsh-cache.json")
        config = JSON.parse(json)
        @client = login(userFound[user.to_s])
        config['User'] = @client.login
        config['user_url'] = @client.web_endpoint.to_s << @client.login.to_s
        save_token(configure_path, userFound[user.to_s])
        return config
      else
        puts 'User not found'
        return nil
      end
    else
      puts "No user's history is available"
      nil
    end
  end

  def load_users(path)
    json = File.read("#{path}/ghedsh-users.json")
    users = JSON.parse(json)
    users
  end

  def return_deep(path)
    json = File.read("#{path}/ghedsh-cache.json")
    cache = JSON.parse(json)
    deep = User
    return deep = Team unless cache['Team'].nil?
    return deep = Organization unless cache['Org'].nil?
    deep
   end

  def add_users(path, data)
    json = File.read("#{path}/ghedsh-users.json")
    users = JSON.parse(json)
    users['users'].push(data)
    File.write("#{path}/ghedsh-users.json", users.to_json)
  end

  def save_token(path, token)
    json = File.read("#{path}/ghedsh-users.json")
    login = JSON.parse(json)
    login['login'] = token
    File.write("#{path}/ghedsh-users.json", login.to_json)
  end

  def get_login_token(path)
    json = File.read("#{path}/ghedsh-users.json")
    us = JSON.parse(json)
    us['login']
  end

  def login(token)
    begin
      user = Octokit::Client.new(access_token: token) # per_page:100
      user.auto_paginate = true # show all pages of any query
    rescue StandardError
      puts 'Oauth error'
    end

    user
  end

  # initial program configure
  def set_loguin_data_sh(config, configure_path)
    prompt = TTY::Prompt.new(enable_color: true)
    username = prompt.ask('Username:', required: true)
    passwd = prompt.ask('Password:', echo: false)

    client = Octokit::Client.new \
      login: username,
      password: passwd
    response = client.create_authorization(scopes: ['user', 'repo', 'admin:org', 'admin:public_key', 'admin:repo_hook', 'admin:org_hook', 'gist', 'notifications', 'delete_repo', 'admin:gpg_key'],
                                           note: 'Probando autenticacion ghdesh')
    token = response[:token]
    us = login(token)
    userhash = {}

    unless us.nil?
      puts Rainbow("Login succesful as #{us.login}\n").green
      config['User'] = us.login
      config['user_url'] = us.web_endpoint << us.login

      add_users(configure_path, (config['User']).to_s => token)
      save_token(configure_path, token)
      @client = us
      return config
    end
  end

  def load_assig_db(path)
    if File.exist?(path) == true
      if File.exist?("#{path}/assignments.json")
        json = File.read("#{path}/assignments.json")
      else
        # {"Organization":[{"name":null,"assignments":[{"name":null,"teams":{"teamid":null}}]}]}
        con = { orgs: [] }
        File.write("#{path}/assignments.json", con.to_json)
        json = File.read("#{path}/assignments.json")
      end
    end
    config = JSON.parse(json)
    config
  end

  def load_people_db(path)
    if File.exist?(path) == true
      if File.exist?("#{path}/ghedsh-people.json")
        json = File.read("#{path}/ghedsh-people.json")
      else
        con = { orgs: [] }
        File.write("#{path}/ghedsh-people.json", con.to_json)
        json = File.read("#{path}/ghedsh-people.json")
      end
    end
    config = JSON.parse(json)
    config
  end

  def load_script(path)
    if File.exist?(path) == true
      script = File.read(path.to_s)
      script.split("\n")
    else
      puts 'No script is found with that name'
      []
    end
  end

  def load_groups(path)
    if File.exist?(path) == true
      if File.exist?("#{path}/groups.json")
        json = File.read("#{path}/groups.json")
      else
        con = { orgs: [] }
        File.write("#{path}/groups.json", con.to_json)
        json = File.read("#{path}/groups.json")
      end
    else
      # path="/db/assignments.json"
      # json = File.read(path)
    end
    config = JSON.parse(json)
    config
  end

  def refresh_clonefile(path, list)
    File.write("#{path}/ghedsh-clonedfiles", list) if File.exist?(path) == true
  end

  def load_clonefile(path)
    if File.exist?(path) == true
      if File.exist?("#{path}/ghedsh-clonedfiles")
        files = File.read("#{path}/ghedsh-clonedfiles")
        files = files.delete('['); files = files.delete(']')
        files = files.split(',')
        files
      else
        File.write("#{path}/ghedsh-clonedfiles", '')
        []
      end
    end
  end

  def create_temp(path)
    FileUtils.mkdir_p(path) if File.exist?(path) == false
  end

  def remove_temp(path)
    system("rm -rf #{path}") if File.exist?(path) == true
  end

  def save_groups(path, data)
    File.write("#{path}/groups.json", data.to_json)
  end

  def save_assigs(path, data)
    File.write("#{path}/assignments.json", data.to_json)
  end

  def save_people(path, data)
    File.write("#{path}/ghedsh-people.json", data.to_json)
  end

  # creates all ghedsh local stuff
  def create_config(configure_path)
    con = { User: nil, user_url: nil, Org: nil, org_url: nil, Repo: nil, repo_url: nil, Team: nil, team_url: nil, TeamID: nil }
    us = { login: nil, users: [] }
    FileUtils.mkdir_p(configure_path)
    File.write("#{configure_path}/ghedsh-cache.json", con.to_json)
    File.write("#{configure_path}/ghedsh-users.json", us.to_json)
    puts "Configuration files created in #{configure_path}"
  end

  def save_cache(path, data)
    File.write("#{path}/ghedsh-cache.json", data.to_json)
  end

  def clear_cache(path)
    con = { User: nil, user_url: nil, Org: nil, org_url: nil, Repo: nil, repo_url: nil, Team: nil, team_url: nil, TeamID: nil }
    File.write("#{path}/ghedsh-cache.json", con.to_json)
  end

  def save_db(path, data)
    File.write("#{path}/db/assignments.json", data.to_json)
  end

  def save_users(path, data)
    File.write("#{path}/ghedsh-users.json", data.to_json)
  end

  def execute_bash(exp)
    system(exp)
  end

  def search_rexp(list, exp)
    list = list.select { |o| o.match(/#{exp}/) }
    list
  end

  def search_rexp_peoplehash(list, exp)
    found = []
    yes = false
    list.each do |i|
      i.each do |j|
        unless j[1].nil?
          yes = true if j[1] =~ /#{exp}/
        end
      end
      if yes == true
        found.push(i)
        yes = false
      end
    end
    found
  end

  def createTempFile(data)
    tempfile = 'temp.txt'
    path = "#{ENV['HOME']}/.ghedsh/#{tempfile}"
    File.write(path, data)
    path
  end

  def showcachelist(list, exp)
    print "\n"
    rlist = []
    options = {}
    o = Organizations.new
    regex = false

    unless exp.nil?
      if exp =~ /^\//
        regex = true
        sp = exp.split('/')
        exp = Regexp.new(sp[1], sp[2])
      end
    end
    counter = 0
    allpages = true

    list.each do |i|
      if regex == false
        if counter == 100 && allpages == true
          op = Readline.readline("\nThere are more results. Show next repositories (press any key) or Show all repositories (press a): ", true)
          allpages = false if op == 'a'
          counter = 0
        end
        puts i
        rlist.push(i)
        counter += 1
      else

        if i.match(exp)
          puts i
          rlist.push(i)
          counter += 1
          end
      end
    end

    if rlist.empty?
      puts 'No repository matches with that expression'
    else
      print "\n"
      puts "Repositories found: #{rlist.size}"
    end
  end

  def loadfile(path)
    if File.exist?(path)
      mem = File.read(path)
      mem = mem.split("\n")
      mem
    else
      puts 'File not found'
      nil
    end
  end

  def open_url(url)
    if RUBY_PLATFORM.downcase.include?('darwin')
      system("open #{url}")
    elsif RUBY_PLATFORM.downcase.include?('linux')
      system("xdg-open #{url}")
    end
  end
end
