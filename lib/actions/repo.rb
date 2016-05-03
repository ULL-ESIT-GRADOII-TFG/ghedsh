require 'readline'
require 'octokit'
require 'json'
require 'readline'
require 'require_all'
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
      when scope==1
        mem=client.commits(config["Org"]+"/"+config["Repo"],"master")
      when scope==2
        mem=client.commits(config["User"]+"/"+config["Repo"],"master")
    end
    mem.each do |i|
      print i[:sha],"\n",i[:commit][:author][:name],"\n",i[:commit][:author][:date],"\n",i[:commit][:message],"\n\n"
    end
  end

  #Show repositories and return a list of them
  #exp = regular expression
  def show_repos(client,config,scope,exp)
    print "\n"
    rlist=[]
    options=Hash.new
    o=Organizations.new
    regex=false

    if exp!=nil
      if exp.match(/^\//)
        regex=true
        sp=exp.split('/')
        exp=sp[1]
      end
    end

    case
      when scope==1
        #options[:affiliation]="organization_member"
        repo=client.repositories(options) #config["User"]
        listorgs=o.read_orgs(client)
        #self.show_user_orgs_repos(client,config,listorgs)

      when scope==2
        repo=client.organization_repositories(config["Org"])
      when scope==3
        repo=client.team_repositories(config["TeamID"])
    end

    counter=0
    allpages=true

    repo.each do |i|
      if regex==false
        if counter==100 && allpages==true
          op=Readline.readline("\nThere are more results. Show next repositories (press any key) or Show all repositories (press a): ",true)
          if op=="a"
            allpages=false
          end
          counter=0
        end

        puts i.name
        rlist.push(i.name)
        counter=counter+1
      else
        if i.name.match(/#{exp}/)
          puts i.name
          rlist.push(i.name)
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
      when scope==1
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
    when scope==1
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
    when scope==2
      puts "created repository in org"
      options[:organization]=config["Org"]
      client.create_repository(repo,options)
    when scope==1
      puts "created repository in user"
      client.create_repository(repo)
    when scope==4
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
      when scope==1
        repo=client.repositories
      when scope==2
        repo=client.organization_repositories(config["Org"])
      when scope==3
        repo=client.team_repositories(config["TeamID"])
    end
    repo.each do |i|
      reposlist.push(i.name)
    end
    return reposlist
  end

  #clone repositories
  #exp = regular expression
  def clone_repo(client,config,exp,scope)
    web="https://github.com/"
    web2="git@github.com:"

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
      when scope==1
        list.each do |i|
          command = "git clone #{web}#{config["User"]}/#{i}.git"
          system(command)
        end
      when scope==2
        list.each do |i|
          command = "git clone #{web}#{config["Org"]}/#{i}.git"
          system(command)
        end
      end
    else
      puts "No repositories found it with the parameters given"
    end
  end
end
