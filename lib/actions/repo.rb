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
    case
    when scope==USER_REPO
        if config["Repo"].split("/").size == 1
          mem=client.commits(config["User"]+"/"+config["Repo"],"master")
        else
          mem=client.commits(config["Repo"],"master")
        end
      when scope==ORGS_REPO
        mem=client.commits(config["Org"]+"/"+config["Repo"],"master")
    end
    mem.each do |i|
      print i[:sha],"\n",i[:commit][:author][:name],"\n",i[:commit][:author][:date],"\n",i[:commit][:message],"\n\n"
    end
  end

  def show_issues(client,config,scope)
      print "\n"
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
      mem.each do |i|
        #print i[:sha],"\n",i[:commit][:author][:name],"\n",i[:commit][:author][:date],"\n",i[:commit][:message],"\n\n"
        puts "##{i[:number]} state: #{i[:state]} -> #{i[:title]} "
      end
      puts "\n"
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
      puts "No repository matches with that expression"
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
      when scope==USER
        mem=client.forks(config["Org"]+"/"+config["Repo"])
    end
    mem.each do |i|
      puts i[:owner][:login]
      forklist.push(i[:owner][:login])
    end
    print "\n"
    return forklist
  end

  def show_collaborators(client,config,scope)
    print "\n"
    collalist=[]
    case
    when scope==USER
      mem=client.collaborators(config["Org"]+"/"+config["Repo"])
    end
    mem.each do |i|
      puts i[:author][:login]
      collalist.push(i[:author][:login])
    end
    print "\n"
    return collalist
  end

  def fork(client,config,repo)
    mem=client.fork(repo)
    return mem
  end

  def create_repository(client,config,repo,scope)
    options=Hash.new
    case
    when scope==ORGS
      puts "created repository in org"
      options[:organization]=config["Org"]
      client.create_repository(repo,options)
    when scope==USER
      puts "created repository in user"
      client.create_repository(repo)
    when scope==TEAM
      puts "created repository in org team"
      options[:team_id]=config["TeamID"]
      options[:organization]=config["Org"]
      client.create_repository(config["Team"]+"/"+repo,options)
    end
  end

  def create_repository_by_teamlist(client,config,repo,list,list_id)
    options=Hash.new
    options[:organization]=config["Org"]
    #puts list_id
    y=0
    list.each do |i|
      options[:team_id]=list_id[y]
      # puts i, list_id[y]
      # puts repo
      # puts options
      # puts "\n"
      client.create_repository(i+"/"+repo,options)
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
