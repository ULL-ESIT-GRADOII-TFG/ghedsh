
class HelpM
  attr_reader :user
  attr_reader :org_repo
  attr_reader :org_teams
  attr_reader :user_repo
  attr_reader :common_opt

  def user()
    self.common_opt
    puts " Users options:"
    print "\torgs\t\t\tShow your organizations\n"
    print "\trepos\t\t\tList your repositories\n"
    print "\tclone\t\t\tClone a repository or a list of repositories using a regular expresion\n"
    print "\tnew_repository\t\tCreate a repository in your personal account\n"
    print "\tset\t\t\tMove you to a specific repository\n"

  end

  def org()
    self.common_opt
    puts " Organization options:"
    print "\trepos\t\t\tList the repositories of your organization\n"
    print "\tclone\t\t\tClone a repository or a list of repositories using a regular expresion\n"
    print "\tset\t\t\tMove you to a specific repository\n"
    print "\tpeople\t\t\tMembers of a organization\n"
    print "\tteams\t\t\tTeams of a organization\n"
    print "\tnew_assignment\t\tCreate a repository in your organization\n"
    print "\trm_team\t\t\tDelete a team in you organization. Expected the name of the team\n"
    print "\tnew_team\t\t\tCreate a team in the organization. Expected the name of the team, and/or members given one by one\n\n"
  end

  def org_repo()
    self.common_opt
    puts " Repository options:"
    print "\tcommits\t\t\tShow the list of commits from the repository\n"
    print "\tissues\t\t\tShow the list of issues from the repository\n"
    print "\tfiles\t\t\tShow the files of the repository path given\n"
    print "\tcat\t\t\tShow data from a file\n"
    print "\tcol\t\t\tShow the list of collaborators from the repository\n\n"
  end

  def orgs_teams()
    self.common_opt
    puts " Organization team options:"
    print "\tpeople\t\t\tMembers of the team\n"
    print "\tclone\t\t\tClone a repository or a list of repositories using a regular expresion\n"
    print "\tnew_repository\t\tCreate a repository to this team\n"
    print "\tadd_to_team\t\t\tAdd a member in the team\n\n"
  end

  def user_repo()
    self.common_opt
    puts " Repository options:"
    print "\tcommits\t\t\tShow the list of commits from the repository\n"
    print "\tissues\t\t\tShow the list of issues from the repository\n"
    print "\tfiles\t\t\tShow the files of the repository path given\n"
    print "\tcat\t\t\tShow data from a file\n"
    print "\tcol\t\t\tShow the list of collaborators from the repository\n\n"
  end
  def team_repo()
    self.common_opt
    puts " Repository options:"
    print "\tcommits\t\t\tShow the list of commits from the repository\n"
    print "\tissues\t\t\tShow the list of issues from the repository\n"
    print "\tfiles\t\t\tShow the files of the repository path given\n"
    print "\tcat\t\t\tShow data from a file\n"
    print "\tcol\t\t\tShow the list of collaborators from the repository\n\n"
  end

  def common_opt()
    puts "\n------------------"
    puts " List of commands "
    puts "------------------"
    puts "\n Main options:"
    print "\tdo\t\t\tRun a script in ghedsh execute path\n"
    print "\texit\t\t\tExit from this program\n"
    print "\thelp\t\t\tList of commands available\n"
    print "\tcd\t\t\tGo to the path\n"
    print "\t!\t\t\tExecute a bash command\n\n"
  end

  def welcome
    puts "\nGitHub Education Shell!"
    puts "_______________________\n\n"
  end

end
