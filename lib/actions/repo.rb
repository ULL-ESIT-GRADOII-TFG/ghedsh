require 'readline'
require 'octokit'
require 'json'
require 'require_all'
require_rel '.'

class Repositories
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
end
