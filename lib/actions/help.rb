
class HelpM
  attr_reader :user
  attr_reader :org_repo
  attr_reader :org_teams
  attr_reader :user_repo
  attr_reader :common_opt

  def user()
    self.common_opt
    puts " Users options:"
    print "\n\tCOMMAND\t\t\tDESCRIPTION\n\n"
    print "\torgs\t\t\tShow your organizations\n"
    print "\topen\t\t\tOpen the user's url of github in your web browser.\n"
    print "\trepos\t\t\tList your repositories\n"
    print "\tclone\t\t\tClone a repository or a list of repositories using a regular expresion\n"
    print "\tnew_repository\t\tCreate a repository in your personal account\n"
    print "\tset\t\t\tMove you to a specific repository\n"

  end

  def org()
    self.common_opt
    puts " Organization options:"
    print "\n\tCOMMAND\t\t\tDESCRIPTION\n\n"
    print "\trepos\t\t\tList the repositories of your organization\n"
    print "\topen\t\t\tOpen the organization's url of github in your web browser.\n"
    print "\t\t\t\tIf you have added the aditional .csv information with, you can open an specific github profile.\n"
    print "\t\t\t\t->\topen [user]\n\n"
    print "\tclone\t\t\tClone a repository or a list of repositories using a regular expresion\n"
    print "\tset\t\t\tMove you to a specific repository\n"
    print "\tpeople\t\t\tShow the members of an organization\n"
    print "\t\t\t\t->\tpeople\n\n"
    print "\t\t\t\tIf you add the parameter 'info', the extended information will be showed\n"
    print "\t\t\t\t->\tpeople info\n\n"
    print "\t\t\t\tTo find a specific member extended info, you can give the github id as parameter.\n"
    print "\t\t\t\t->\tpeople info [github id]\n\n"
    print "\tteams\t\t\tTeams of a organization\n"
    print "\tnew people info\t\tGet extended information from a .csv file founded in the excecute path\n"
    print "\t\t\t\t->\tnew people info [name of the file]\n\n"
    print "\trm people info\t\tDelete the extended information\n"
    print "\tassignments\t\tShow the list of assignments created\n"
    print "\tnew_assignment\t\tCreate an Assignment in your organization\n"
    print "\tgroups\t\t\tShow the list of groups with each team and user that it has\n"
    print "\tgroup\t\t\tShow the information of an specific group\n"
    print "\t\t\t\t->\tgroup [name of the group]\n\n"
    print "\tnew_group\t\tCreate a new group. Expected the name and teams given one by one\n"
    print "\t\t\t\t->\tnew_group [name of the group] [team1] [team2] [team3] ... \n\n"
    print "\trm_group\t\tDelete a created group\n"
    print "\t\t\t\t->\trm_group [name of the group]\n\n"
    print "\trm_team\t\t\tDelete a team in you organization. Expected the name of the team\n"
    print "\t\t\t\t->\trm team [name of the team]\n\n"
    print "\tnew team\t\tCreate a team in the organization. Expected the name of the team, and/or members given one by one\n"
    print "\t\t\t\t->\tnew team [name of the team] [member1] [member2] [member3] ... \n\n"

  end

  def org_repo()
    self.common_opt
    puts " Repository options:"
    print "\n\tCOMMAND\t\t\tDESCRIPTION\n\n"
    print "\tinfo\t\t\tShow information about the repository\n"
    print "\topen\t\t\tOpen the repository's url of github in your web browser.\n"
    print "\tcommits\t\t\tShow the list of commits from the repository\n"
    print "\tnew issue\t\tCreates a new issue\n"
    print "\tissues\t\t\tShow the list of issues from the repository\n"
    print "\tissue\t\t\tShow the issue and its comments\n"
    print "\t\t\t\t->\tissue [Id of the issue]\n\n"
    print "\tnew issue comment\tAdd a comment in a specific issue\n"
    print "\t\t\t\t->\tnew issue comment [Id of the issue]\n\n"
    print "\topen_issue\t\tOpen a closed issue\n"
    print "\t\t\t\t->\topen_issue [Id of the issue]\n\n"
    print "\tclose_issue\t\tClose an opened issue\n"
    print "\t\t\t\t->\tclose_issue [Id of the issue]\n\n"
    print "\tfiles\t\t\tShow the files of the repository path given\n"
    print "\tcat\t\t\tShow data from a file\n"
    print "\t\t\t\t->\tcat [file]\n\n"
    print "\tprivate\t\t\tChange the privacy of a repository. Expected 'true' or 'false' as parameter.\n"
    print "\t\t\t\t->\tprivate [true]\n\n"
    print "\tcol\t\t\tShow the list of collaborators from the repository\n\n"
  end

  def orgs_teams()
    self.common_opt
    puts " Organization team options:"
    print "\n\tCOMMAND\t\t\tDESCRIPTION\n\n"
    print "\tpeople\t\t\tMembers of the team\n"
    print "\topen\t\t\tOpen the team's url of github in your web browser.\n"
    print "\tclone\t\t\tClone a repository or a list of repositories using a regular expresion\n"
    print "\tnew_repository\t\tCreate a repository to this team\n"
    print "\tadd_to_team\t\tAdd a member in the team\n\n"
  end

  def user_repo()
    self.common_opt
    puts " Repository options:"
    print "\n\tCOMMAND\t\t\tDESCRIPTION\n\n"
    print "\tinfo\t\t\tShow information about the repository\n"
    print "\topen\t\t\tOpen the repository's url of github in your web browser.\n"
    print "\tcommits\t\t\tShow the list of commits from the repository\n"
    print "\tnew issue\t\tCreates a new issue\n"
    print "\tissues\t\t\tShow the list of issues from the repository\n"
    print "\tissue\t\t\tShow the issue and its comments\n"
    print "\t\t\t\t->\tissue [Id of the issue]\n\n"
    print "\tnew issue comment\tAdd a comment in a specific issue\n"
    print "\t\t\t\->\tnew issue comment [Id of the issue]\n\n"
    print "\topen_issue\t\tOpen a closed issue\n"
    print "\t\t\t\t->\topen_issue [Id of the issue]\n\n"
    print "\tclose_issue\t\tClose an opened issue\n"
    print "\t\t\t\t->\tclose_issue [Id of the issue]\n\n"
    print "\tfiles\t\t\tShow the files of the repository path given\n"
    print "\tcat\t\t\tShow data from a file\n"
    print "\t\t\t\t->\tcat [file]\n\n"
    print "\tprivate\t\t\tChange the privacy of a repository. Expected 'true' or 'false' as parameter.\n"
    print "\t\t\t\t->\tprivate [true]\n\n"
    print "\topen\t\t\tOpen the repository's url of github in your web browser.\n"
    print "\tcol\t\t\tShow the list of collaborators from the repository\n\n"
  end

  def asssig()
    self.common_opt
    puts " Assignment options:"
    print "\n\tCOMMAND\t\t\tDESCRIPTION\n\n"
    print "\tinfo\t\t\Show information about the assignment\n"
    print "\tadd repo\t\tAdd or create the repository of the assignment\n"
    print "\tadd group\t\tAdd a new group to the assignment\n"
    print "\tmake\t\t\tCreate the repository assignment in Github for each team of every group\n\n"
  end

  def team_repo()
    self.common_opt
    puts " Repository options:"
    print "\n\tCOMMAND\t\t\tDESCRIPTION\n\n"
    print "\tinfo\t\t\tShow information about the repository\n"
    print "\topen\t\t\tOpen the repository's url of github in your web browser.\n"
    print "\tcommits\t\t\tShow the list of commits from the repository\n"
    print "\tnew issue\t\tCreates a new issue\n"
    print "\tissues\t\t\tShow the list of issues from the repository\n"
    print "\tissue\t\t\tShow the issue and its comments\n"
    print "\tnew issue comment\tAdd a comment in a specific issue\n"
    print "\t\t\t\t->\tnew issue comment [Id of the issue]\n\n"
    print "\t\t\t\t->\tissue [Id of the issue]\n\n"
    print "\topen_issue\t\tOpen a closed issue\n"
    print "\t\t\t\t->\topen_issue [Id of the issue]\n\n"
    print "\tclose_issue\t\tClose an opened issue\n"
    print "\t\t\t\t->\tclose_issue [Id of the issue]\n\n"
    print "\tfiles\t\t\tShow the files of the repository path given\n"
    print "\tcat\t\t\tShow data from a file\n"
    print "\t\t\t\t->\tcat [file]\n\n"
    print "\tprivate\t\t\tChange the privacy of a repository. Expected 'true' or 'false' as parameter.\n"
    print "\t\t\t\t->\tprivate [true]\n\n"
    print "\tcol\t\t\tShow the list of collaborators from the repository\n\n"
  end

  def common_opt()
    puts "\n------------------"
    puts " List of commands "
    puts "------------------"
    puts "\n Main options:"
    print "\n\tCOMMAND\t\t\tDESCRIPTION\n\n"
    print "\tdo\t\t\tRun a script in ghedsh execute path\n"
    print "\t\t\t\t->\tdo [filename]\n\n"
    print "\texit\t\t\tExit from this program\n"
    print "\thelp\t\t\tList of commands available\n"
    print "\tcd\t\t\tGo to the path. Could be an assignment, an organization, a team or a repository\n"
    print "\t\t\t\t->\tcd [path]\n\n"
    print "\t\t\t\tFor going to the user root path use cd without argument:\n"
    print "\t\t\t\t->\tcd\n\n"
    print "\t\t\t\tYou can go back to the previous level with the argument ".."\n"
    print "\t\t\t\t->\tcd [..]\n\n"
    print "\t\t\t\tDefault search look for repositories at the end of the queue.\n"
    print "\t\t\t\tIf you want to look for an specific repository use: \n"
    print "\t\t\t\t->\tcd repo [name] \n\n"
    print "\t!\t\t\tExecute a bash command\n\n"
  end

  def welcome
    puts "\nGitHub Education Shell!"
    puts "_______________________\n\n"
  end

end
