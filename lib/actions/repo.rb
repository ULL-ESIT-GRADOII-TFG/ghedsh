require 'readline'
require 'octokit'
require 'json'
require 'readline'
require 'require_all'
require 'base64'
require_rel '.'

class Repositories
  attr_reader :reposlist
  #scope = 1 -> organization repos
  #scope = 2 -> user repos
  #scope = 3 -> team repos

  def initialize
    @reposlist=[]
  end

  def show_commits(client,config,scope)
    print "\n"
    empty=0
    begin
      case
      when scope==USER_REPO
          if config["Repo"].split("/").size == 1
            mem=client.commits(config["User"]+"/"+config["Repo"],"master")
          else
            mem=client.commits(config["Repo"],"master")
          end
      when scope==ORGS_REPO || scope==TEAM_REPO
          mem=client.commits(config["Org"]+"/"+config["Repo"],"master")
      end
    rescue
      puts "The Repository is empty"
      empty=1
    end
    if empty==0
      mem.each do |i|
        print i[:sha],"\n",i[:commit][:author][:name],"\n",i[:commit][:author][:date],"\n",i[:commit][:message],"\n\n"
      end
    end
  end

  def info_repository(client,config,scope)
    empty=0
    begin
      case
      when scope==USER_REPO
          if config["Repo"].split("/").size == 1
            mem=client.repository(config["User"]+"/"+config["Repo"])
          else
            mem=client.repository(config["Repo"])
          end
      when scope==ORGS_REPO || scope==TEAM_REPO
          mem=client.repository(config["Org"]+"/"+config["Repo"])
      end
      rescue
       puts "The Repository is empty"
       empty=1
    end
    if empty==0
      puts "\n Name: \t\t#{mem[:name]}"
      puts " Full name: \t#{mem[:full_name]}"
      puts " Description: \t#{mem[:description]}"
      puts " Private: \t#{mem[:private]}"
      puts "\n Created: \t#{mem[:created_at]}"
      puts " Last update: \t#{mem[:updated_at]}"
      puts " Url: \t\t#{mem[:html_url]}"
      puts
    end
  end

  def create_issue(client,config,scope)
    puts "Insert Issue tittle: "
    tittle=gets.chomp
    puts "Add a description: "
    desc=gets.chomp

    case
    when scope==USER_REPO
      if config["Repo"].split("/").size == 1
        client.create_issue(config["User"]+"/"+config["Repo"],tittle,desc)
      else
        client.create_issue(config["Repo"],tittle,desc)
      end
    when scope==ORGS_REPO || scope==TEAM_REPO
      client.create_issue(config["Org"]+"/"+config["Repo"],tittle,desc)
    end
  end

  def close_issue(client,config,scope,id)
    case
    when scope==USER_REPO
      if config["Repo"].split("/").size == 1
        client.close_issue(config["User"]+"/"+config["Repo"],id)
      else
        client.close_issue(config["Repo"],id)
      end
    when scope==ORGS_REPO || scope==TEAM_REPO
      client.close_issue(config["Org"]+"/"+config["Repo"],id)
    end
  end

  def open_issue(client,config,scope,id)
    case
    when scope==USER_REPO
      if config["Repo"].split("/").size == 1
        client.reopen_issue(config["User"]+"/"+config["Repo"],id)
      else
        client.reopen_issue(config["Repo"],id)
      end
    when scope==ORGS_REPO || scope==TEAM_REPO
      client.reopen_issue(config["Org"]+"/"+config["Repo"],id)
    end
  end

  def get_issues(client,config,scope)
    case
    when scope==USER_REPO
      if config["Repo"].split("/").size == 1
        mem=client.list_issues(config["User"]+"/"+config["Repo"],{:state=>"all"})
      else
        mem=client.list_issues(config["Repo"],{:state=>"all"})
      end
    when scope==ORGS_REPO || scope==TEAM_REPO
        mem=client.list_issues(config["Org"]+"/"+config["Repo"],{:state=>"all"})
    end
    return mem
  end

  #show all issues from a repository
  def show_issues(client,config,scope)
      print "\n"
      mem=self.get_issues(client,config,scope)
      mem.each do |i|
        #print i[:sha],"\n",i[:commit][:author][:name],"\n",i[:commit][:author][:date],"\n",i[:commit][:message],"\n\n"
        puts "##{i[:number]} state: #{i[:state]} -> #{i[:title]} "
      end
      print "\n"
      return mem
  end

  #show an specific issue from a repository
  def show_issue(client,config,scope,id)
    issfound=0
    issues_list=self.get_issues(client,config,scope)
    if issues_list!=nil
      issues_list.each do |i|
        if i[:number]==id.to_i
          puts
          puts "  --------------------------------------"
          puts "  Author: #{i[:user][:login]}"
          puts "  ##{i[:number]} state: #{i[:state]}"
          puts "  Tittle: #{i[:title]}"
          puts "  --------------------------------------"
          puts "\n#{i[:body]}"
          issfound=1
          print "\nShow comments (Press any key to proceed, or only enter to skip) -> "
          show=gets.chomp
          puts
          if show!=""
            self.show_issues_cm(client,config,scope,i[:number])
          end
        end
      end
    end
    if issfound==0
      puts "Issue not found"
    end
    puts "\n"
  end

  #show issues comment
  def show_issues_cm(client,config,scope,id)
    case
    when scope==USER_REPO
      if config["Repo"].split("/").size == 1
        mem=client.issue_comments(config["User"]+"/"+config["Repo"],id)
      else
        mem=client.issue_comments(config["Repo"],id)
      end
    when scope==ORGS_REPO || scope==TEAM_REPO
        mem=client.issue_comments(config["Org"]+"/"+config["Repo"],id)
    end
    if mem!=nil
      puts
      puts " < COMMENTS (#{mem.size}) >"
      mem.each do |i|
        puts
        puts " --------------------------------------"
        puts " Author: #{i[:user][:login]} "
        puts " Date: #{i[:created_at]}"
        puts " --------------------------------------"
        puts "\n#{i[:body]}"
      end
    else
      puts "No comments have been added yet"
    end
  end

  #add issue comment
  def add_issue_cm
  end

  #Show repositories and return a list of them
  #exp = regular expression
  def show_repos(client,config,scope,exp)
    print "\n"
    rlist=[]
    options=Hash.new
    o=Organizations.new
    regex=false
    force_exit=false

    if exp!=nil
      if exp.match(/^\//)
        regex=true
        sp=exp.split('/')
        exp=Regexp.new(sp[1],sp[2])
      end
    end

    case
      when scope==USER
        repo=client.repositories(options) #config["User"]
        listorgs=o.read_orgs(client)
      when scope==ORGS
        repo=client.organization_repositories(config["Org"])
      when scope==TEAM
        repo=client.team_repositories(config["TeamID"])
    end

    counter=0
    allpages=true

    repo.each do |i|
      if force_exit==false
        if regex==false
          if counter==100 && allpages==true
            op=Readline.readline("\nThere are more results. Show next repositories (press any key), show all repositories (press a) or quit (q): ",true)
            if op=="a"
              allpages=false
            end
            if op=="q"
              force_exit=true
            end
            counter=0
          end
          if scope ==USER
            if i[:owner][:login]==config["User"]
              puts i.name
              rlist.push(i.name)
            else
              puts i.full_name
              rlist.push(i.full_name)
            end
          else
            puts i.name
            rlist.push(i.name)
          end
          counter=counter+1
        else
          if i.name.match(exp)
            if scope ==USER
              puts i.full_name
              rlist.push(i.full_name)
            else
              puts i.name
              rlist.push(i.name)
            end
              counter=counter+1
            end
        end
      end
    end

    if rlist.empty?
      puts "\e[31m No repository matches with that expression\e[0m"
    else
      print "\n"
      puts "Repositories found: #{rlist.size}"
    end

    return rlist
  end

  def show_user_orgs_repos(client,config,listorgs)
    options=Hash.new
    options[:member]=config["User"]
    listorgs.each do |i|
      repo=client.organization_repositories(i,options)
          repo.each do |y|
            puts y.name
          end
    end
  end

  def show_forks(client,config,scope)
    print "\n"
    forklist=[]
    case
    when scope==USER_REPO
      if config["Repo"].split("/").size == 1
        mem=client.forks(config["User"]+"/"+config["Repo"],"master")
      else
        mem=client.forks(config["Repo"],"master")
      end
    when scope==ORGS_REPO || scope==TEAM_REPO
        mem=client.forks(config["Org"]+"/"+config["Repo"])
    end
    if mem.size==0
      puts "No forks found in this repository"
    else
      mem.each do |i|
        puts i[:login]
        forklist.push(i[:login])
      end
      print "\n"
      return forklist
    end
  end

  def show_collaborators(client,config,scope)
    print "\n"
    collalist=[]
    case
    when scope==USER_REPO
      if config["Repo"].split("/").size == 1
        mem=client.collaborators(config["User"]+"/"+config["Repo"],"master")
      else
        mem=client.collaborators(config["Repo"],"master")
      end
    when scope==ORGS_REPO || scope==TEAM_REPO
      mem=client.collaborators(config["Org"]+"/"+config["Repo"])
    end
    print " Collaborators\n\n"
    mem.each do |i|
      puts " #{i[:login]}"
      collalist.push(i[:login])
    end
    print "\n"
    return collalist
  end

  def fork(client,config,repo)
    mem=client.fork(repo)
    return mem
  end

  def delete_repository(client,config,repo,scope)
    if scope==ORGS
      if client.repository?("#{config["Org"]}/#{repo}")==false
        puts "\e[31m It doesn't exist a repository with that name in #{config["Org"]}\e[0m"
      else
        ex=false
        until ex==true
          puts "Repository #{repo} will be delete. Are you sure? (yes/no) (y/n)"
          op=gets.chomp
          if op=="yes" or op=="y"
            client.delete_repository("#{config["Org"]}/#{repo}")
            ex=true
          end
          if op=="no" or op=="n" then ex=true end
        end
      end
    end
    if scope==USER || scope==TEAM
      if client.repository?("#{config["User"]}/#{repo}")==false
        puts "\e[31m It doesn't exist a repository with that name in #{config["User"]}\e[0m"
      else
        ex=false
        until ex==true
          puts "Repository #{repo} will be delete. Are you sure? (yes/no) (y/n)"
          op=gets.chomp
          if op=="yes" or op=="y"
            client.delete_repository("#{config["User"]}/#{repo}")
            ex=true
          end
          if op=="no" or op=="n" then ex=true end
        end
      end
    end
  end

  def create_repository(client,config,repo,empty,scope)
    options=Hash.new
    if empty==false
      options[:auto_init]=true
    end

    case
    when scope==ORGS
      options[:organization]=config["Org"]
      if client.repository?("#{config["Org"]}/#{repo}")==false
        client.create_repository(repo,options)
        puts "created repository in #{config["Org"]}"
        return true
      else
        puts "\e[31m Already exists a repository with that name in #{config["Org"]}\e[0m"
        return false
      end
    when scope==USER
      if client.repository?("#{config["User"]}/#{repo}")==false
        client.create_repository(repo)
        puts "created repository #{config["User"]}"
        return true
      else
        puts "\e[31m Already exists a repository with that name in #{config["User"]}\e[0m"
        return false
      end
    when scope==TEAM
      puts "created repository in #{config["Org"]} team"
      options[:team_id]=config["TeamID"]
      options[:organization]=config["Org"]

      if client.repository?("#{config["Org"]}/#{repo}")==false
        client.create_repository(repo,options)
        puts "created repository in #{config["Org"]} for team #{config["Team"]}"
        return true
      else
        puts "\e[31m Already exists a repository with that name in #{config["Org"]}\e[0m"
        return false
      end
    end
  end

  def edit_repository(client, config, scope, privacy)
    options=Hash.new
    if privacy=="true"
      privacy=true
    else
      privacy=false
    end
    options[:private]=privacy
    begin
      case
      when scope==USER_REPO
        if config["Repo"].split("/").size == 1
          mem=client.edit_repository(config["User"]+"/"+config["Repo"],options)
        else
          mem=client.edit_repository(config["Repo"],options)
        end
      when scope==ORGS_REPO || scope==TEAM_REPO
          mem=client.edit_repository(config["Org"]+"/"+config["Repo"],options)
      end
    rescue
      puts "Not allow to change privacy"
    end
  end

  def change_privacy(client,config,repo,list,list_id,privacy)
    list.each do |i|
    end
  end

  def create_repository_by_teamlist(client,config,repo,list,list_id)
    options=Hash.new
    options[:organization]=config["Org"]
    y=0
    list.each do |i|
      options[:team_id]=list_id[y]
      client.create_repository(i+"/"+repo,false,options)
      y=y+1
    end
  end

  #Gete the repository list from a given scope
  def get_repos_list(client,config,scope)
    reposlist=[]
    case
      when scope==USER
        repo=client.repositories
      when scope==ORGS
        repo=client.organization_repositories(config["Org"])
      when scope==TEAM
        repo=client.team_repositories(config["TeamID"])
    end
    repo.each do |i|
      if scope!=USER
        reposlist.push(i.name)
      else
        if i[:owner][:login]==config["User"]
          reposlist.push(i.name)
        else
          reposlist.push(i.full_name)
        end
      end
    end
    return reposlist
  end

  #clone repositories
  #exp = regular expression
  def clone_repo(client,config,exp,scope)
    web="https://github.com/"
    web2="git@github.com:"

    if scope==USER_REPO || scope==TEAM_REPO || scope==ORGS_REPO
      case
        when scope==USER_REPO
          if config["Repo"].split("/").size == 1
            command = "git clone #{web2}#{config["User"]}/#{config["Repo"]}.git"
          else
            command = "git clone #{web2}#{config["Repo"]}.git"
          end
        when scope==TEAM_REPO
          command = "git clone #{web2}#{config["Org"]}/#{config["Repo"]}.git"
        when scope==ORGS_REPO
          command = "git clone #{web2}#{config["Org"]}/#{config["Repo"]}.git"
      end
        system(command)
    else
      if exp.match(/^\//)
        exps=exp.split('/')
        list=self.get_repos_list(client,config,scope)
        list=Sys.new.search_rexp(list,exps[1])
      else
        list=[]
        list.push(exp)
      end

      if (list.empty?) == false
        case
        when scope==USER
          list.each do |i|
            command = "git clone #{web2}#{config["User"]}/#{i}.git"
            system(command)
          end
        when scope==ORGS
          list.each do |i|
            command = "git clone #{web2}#{config["Org"]}/#{i}.git"
            system(command)
          end
        end
      else
        puts "No repositories found it with the parameters given"
      end
    end
  end

  def show_files(list)
    print "\n"

    list.each do |i|
      if i.name.match(/.\./)!=nil
        puts i.name
      else
        puts "\e[33m#{i.name}\e[0m"
      end
    end
    print "\n"
  end

  def cat_file(client,config,path,scope)
    if path.match(/.\./)!=nil
      case
      when scope==USER_REPO
        if config["Repo"].split("/").size > 1
          begin
            data=Base64.decode64(client.content(config["Repo"],:path=>path).content)
          rescue Exception, Interrupt
            puts "File not found"
          end
        else
          begin
            data=Base64.decode64(client.content(config["User"]+"/"+config["Repo"],:path=>path).content)
          rescue Exception, Interrupt
            puts "File not found"
          end
        end

      when scope==ORGS_REPO
        begin
          data=Base64.decode64(client.content(config["Org"]+"/"+config["Repo"],:path=>path).content)
        rescue Exception, Interrupt
          puts "File not found"
        end
      when scope==TEAM_REPO
        begin
          data=Base64.decode64(client.content(config["Org"]+"/"+config["Repo"],:path=>path).content)
        rescue Exception, Interrupt
          puts "File not found"
        end
      end
      # s=Sys.new()
      # s.createTempFile(data)
      # s.execute_bash("vi -R #{data}")
      puts data
    else
      puts "#{path} is not a file."
    end
  end

  def get_files(client,config,path,show,scope)
    #show=true
    if path.match(/.\./)==nil
      case
      when scope==USER_REPO
        if config["Repo"].split("/").size > 1
          begin
            list=client.content(config["Repo"],:path=>path)
          rescue Exception, Interrupt => e
            puts "No files found"
            show=false
          end
        else
          begin
            list=client.content(config["User"]+"/"+config["Repo"],:path=>path)
          rescue Exception, Interrupt => e
            puts "No files found"
            show=false
          end
        end

      when scope==ORGS_REPO
        begin
          list=client.content(config["Org"]+"/"+config["Repo"],:path=>path)
        rescue Exception, Interrupt => e
          puts "No files found"
          show=false
        end
      when scope==TEAM_REPO
        begin
          list=client.content(config["Org"]+"/"+config["Repo"],:path=>path)
        rescue Exception, Interrupt => e
          puts "No files found"
          show=false
        end
      end
      if show!=false
        self.show_files(list)
      else
        return list
      end
    else
      puts "#{path} is not a directory. If you want to open a file try to use cat <path>"
    end
  end
end
