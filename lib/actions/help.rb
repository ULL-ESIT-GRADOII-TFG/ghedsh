
class HelpM
  attr_reader :user
  attr_reader :org_repo
  attr_reader :org_teams
  attr_reader :user_repo
  attr_reader :common_opt

  def user()
    self.common_opt
    print "\torgs\t\t\tshow your organizations\n"
    print "\trepos\t\t\tlist your repositories\n\n"
    print "\tclone\t\t\tclone a repository or a list of repositories using a regular expresion\n"
    print "\tnew_repository\t\tcreate a repository in your personal account\n"
    print "\tset\t\t\tmove you to a specific repository\n"

  end

  def org()
    self.common_opt
    print "\trepos\t\t\tlist the repositories of your organization\n"
    print "\tclone\t\t\tclone a repository or a list of repositories using a regular expresion\n"
    print "\tset\t\t\tmove you to a specific repository\n"
    print "\tpeople\t\t\tmembers of a organization\n"
    print "\tteams\t\t\tteams of a organization\n"
    print "\tnew_assignment\t\tcreate a repository in your organization\n"
    print "\trm_team\t\t\tdelete a team in you organization. Expected the name of the team\n"
    print "\tnew_team\t\t\tcreate a team in the organization. Expected the name of the team, and/or members given one by one\n\n"
  end

  def org_repo()
    self.common_opt
    print "\tcommits\t\t\tshow the list of commits from the repository\n"
    print "\tissues\t\t\tshow the list of issues from the repository\n"
    print "\tfiles\t\t\tshow the files of the repository path given\n"
    print "\tcat\t\t\tshow data from a file\n"
    print "\tcol\t\t\tshow the list of collaborators from the repository\n\n"
  end

  def orgs_teams()
    self.common_opt
    print "\tpeople\t\t\tmembers of the team\n"
    print "\tclone\t\t\tclone a repository or a list of repositories using a regular expresion\n"
    print "\tnew_repository\t\tcreate a repository to this team\n"
    print "\tadd_to_team\t\t\tadd a member in the team\n\n"
  end

  def user_repo()
    self.common_opt
    print "\tcommits\t\t\tshow the list of commits from the repository\n"
    print "\tissues\t\t\tshow the list of issues from the repository\n"
    print "\tfiles\t\t\tshow the files of the repository path given\n"
    print "\tcat\t\t\tshow data from a file\n"
    print "\tcol\t\t\tshow the list of collaborators from the repository\n\n"
  end
  def team_repo()
    self.common_opt
    print "\tcommits\t\t\tshow the list of commits from the repository\n"
    print "\tissues\t\t\tshow the list of issues from the repository\n"
    print "\tfiles\t\t\tshow the files of the repository path given\n"
    print "\tcat\t\t\tshow data from a file\n"
    print "\tcol\t\t\tshow the list of collaborators from the repository\n\n"
  end

  def common_opt()
    puts "\nList of commands\n"
    print "\texit\t\t\texit from this program\n"
    print "\thelp\t\t\tlist of commands available\n"
    print "\tcd\t\t\tgo to the path\n"
    print "\t!\t\t\texecute a bash command\n"
  end

  def welcome
    puts "\nGitHub Education Shell!"
    puts "_______________________\n\n"
  end

end
