require 'require_all'
require_rel '.'

class HelpM
  attr_reader :user
  attr_reader :org_repo
  attr_reader :org_teams
  attr_reader :user_repo
  attr_reader :common_opt

  def context(name,scope)
    name=name.join("_")
    begin
      self.send(:"#{name}",scope)
    rescue
      puts "There is no command with that name"
    end
  end

  def clone(scope)
    case
    when scope==USER || scope==ORGS
      print "\tclone\t\t\tClone a repository.\n"
      print "\t\t\t\t->\tclone [repository]\n\n"
      print "\t\t\t\tYou can use a RegExp to clone several repositories with \/ parameter \n"
      print "\t\t\t\t->\tclone /[RegExp]/\n\n"
    when scope==USER_REPO || scope==TEAM_REPO || scope==ORGS_REPO
      print "\tclone\t\t\tClone the current repository.\n"
    end
  end

  def repos(scope)
    case
    when scope==USER
      print "\trepos\t\t\tList your repositories\n"
    when scope==ORGS
      print "\trepos\t\t\tList the repositories of your organization\n"
    when scope==TEAM
      print "\trepos\t\t\tList the team's repositories\n"
    end
    print "\t\t\t\tUse the parameter -a, to directly show all repositories\n"
    print "\t\t\t\t->\trepos -a\n\n"
    print "\t\t\t\tYou can use a RegExp to improve the search using the \/ parameter \n"
    print "\t\t\t\t->\trepos /[RegExp]/\n\n"
  end

  def new_repository(scope)
    case
    when scope==USER
      print "\tnew repository\t\tCreate a repository in your personal account\n"
    when scope==ORGS
      print "\tnew repository\t\tCreate a repository in a organization\n"
    when scope==TEAM
      print "\tnew repository\t\tCreate a repository to this team\n"
    end
    print "\t\t\t\t->\tnew repository [name of the repository]\n\n"
  end

  def rm_repository(scope)
    case
    when scope==USER
      print "\trm repository\t\tDelete a repository in your personal account\n"
    when scope==ORGS
      print "\trm repository\t\tDelete a repository in a organization\n"
    when scope==TEAM
      print "\trm repository\t\tDelete a repository of a team\n"
    end
    print "\t\t\t\t->\trm repository [name of the repository]\n\n"
  end

  def open(scope)
    case
    when scope==USER
      print "\topen\t\t\tOpen the user's url of github in your web browser.\n"
    when scope==ORGS
      print "\topen\t\t\tOpen the organization's url of github in your web browser.\n"
      print "\t\t\t\tIf you have added the aditional .csv information with, you can open an specific github profile.\n"
      print "\t\t\t\t->\topen [user]\n\n"
      print "\t\t\t\tYou can use a RegExp to open several users.\n"
      print "\t\t\t\t->\topen /RegExp/\n\n"
      print "\t\t\t\tYou can open an specific field if its contains an url.\n"
      print "\t\t\t\t->\topen [user] [fieldname]\n\n"
      print "\t\t\t\tIf you don't want to put the whole field, you can open the url contained with \"/\" parameter.\n"
      print "\t\t\t\t->\topen [user] /[part of the url]/\n\n"
      print "\t\t\t\tYo can also use the RegExp in first parameter too, in order to open several websites.\n"
      print "\t\t\t\t->\topen /RegExp/ /[part of the url]/\n\n"
    when scope==ORGS_REPO
      print "\topen\t\t\tOpen the repository's url of github in your web browser.\n"
    when scope==TEAM
      print "\topen\t\t\tOpen the team's url of github in your web browser.\n"
    when scope==TEAM_REPO
      print "\topen\t\t\tOpen the repository's url of github in your web browser.\n"
    when scope==ASSIG
      print "\topen\t\t\topen the github assignment repositories disposition\n"
    end
  end

  def people(scope)
    case
    when scope==ORGS
      print "\tpeople\t\t\tMembers of the organization\n"
      print "\t\t\t\t->\tpeople\n\n"
      print "\t\t\t\tIf you add the parameter 'info', the extended information will be showed\n"
      print "\t\t\t\t->\tpeople info\n\n"
      print "\t\t\t\tTo find a specific member extended info, you can give the github id as parameter.\n"
      print "\t\t\t\t->\tpeople info [github id]\n\n"
      print "\t\t\t\tTo use a RegExp search in each field of the information, you can use the parameter /.\n"
      print "\t\t\t\t->\tpeople info /[RegExp]/\n\n"
    when scope==TEAM
      print "\tpeople\t\t\tMembers of the team\n"
    end
  end
  alias_method :people_info, :people

  def cd(scope)
    print "\tcd\t\t\tGo to the path. Could be an assignment, an organization, a team or a repository\n"
    print "\t\t\t\t->\tcd [path]\n\n"
    print "\t\t\t\tFor going to the user root path use cd without argument:\n"
    print "\t\t\t\t->\tcd\n\n"
    print "\t\t\t\tYou can go back to the previous level with the argument ".."\n"
    print "\t\t\t\t->\tcd [..]\n\n"
    print "\t\t\t\tDefault search look for repositories at the end of the queue.\n"
    print "\t\t\t\tIf you want to look for an specific repository use: \n"
    print "\t\t\t\t->\tcd repo [name] \n\n"
  end

  def groups(scope)
    case
    when scope==ORGS
      print "\tgroups\t\t\tShow the list of groups with each team and user that it has\n"
      print "\tgroup\t\t\tShow the information of an specific group\n"
      print "\t\t\t\t->\tgroup [name of the group]\n\n"
      print "\tnew group\t\tCreate a new group. Expected the name and teams given one by one\n"
      print "\t\t\t\t->\tnew group [name of the group] [team1] [team2] [team3] ... \n\n"
      print "\t\t\t\tIf you want to import the teams from a file, use the parameter -f\n"
      print "\t\t\t\t->\tnew group -f [name of the group] [file]\n\n"
      print "\trm group\t\tDelete a created group\n"
      print "\t\t\t\t->\trm group [name of the group]\n\n"
    end
  end
  alias_method :group,:groups
  alias_method :new_group,:groups
  alias_method :rm_group,:groups

  def teams(scope)
    case
    when scope==ORGS
      print "\tteams\t\t\tTeams of a organization\n"
      print "\trm team\t\t\tDelete a team in you organization. Expected the name of the team\n"
      print "\t\t\t\t->\trm team [name of the team]\n\n"
      print "\tnew team\t\tCreate a team in the organization. Expected the name of the team, and/or members given one by one\n"
      print "\t\t\t\t->\tnew team [name of the team] [member1] [member2] [member3] ... \n\n"
    end
  end
  alias_method :rm_team, :teams
  alias_method :new_team, :teams

  def assignments(scope)
    case
    when scope==ORGS
      print "\tassignments\t\tShow the list of assignments created\n"
      print "\tnew assignment\t\tCreate an Assignment in your organization\n"
      print "\t\t\t\t->\tnew assignment [name of the assignment]\n\n"
    end
  end
  alias_method :new_assignment, :assignments

  def issues(scope)
    if scope==ORGS_REPO || scope==TEAM_REPO || scope==USER_REPO
      print "\tnew issue\t\tCreates a new issue\n"
      print "\tissues\t\t\tShow the list of issues from the repository\n"
      print "\tissue\t\t\tShow the issue and its comments\n"
      print "\t\t\t\t->\tissue [Id of the issue]\n\n"
      print "\tnew issue comment\tAdd a comment in a specific issue\n"
      print "\t\t\t\t->\tnew issue comment [Id of the issue]\n\n"
      print "\topen issue\t\tOpen a closed issue\n"
      print "\t\t\t\t->\topen issue [Id of the issue]\n\n"
      print "\tclose issue\t\tClose an opened issue\n"
      print "\t\t\t\t->\tclose issue [Id of the issue]\n\n"
    end
  end
  alias_method :new_issue,:issues
  alias_method :issue,:issues
  alias_method :open_issue,:issues
  alias_method :close_issue,:issues

  def new_people_info(scope)
    if scope==ORGS
      print "\tnew relation\t\tSet a relation for the extendend information between Github ID and an email from a .csv file\n"
      print "\t\t\t\t->\tnew relation [name of the file]\n\n"
      print "\tnew people info\t\tGet extended information from a .csv file founded in the excecute path\n"
      print "\t\t\t\t->\tnew people info [name of the file]\n\n"
      print "\trm people info\t\tDelete the extended information\n"
    end
  end
  alias_method :new_relation,:new_people_info
  alias_method :rm_people_info,:new_people_info

  def info(scope)

    if scope==USER
    end
    if scope==USER_REPO || scope==ORGS_REPO || scope==TEAM_REPO
      print "\tinfo\t\t\tShow information about the repository\n"
    end
    if scope==ASSIG
      print "\tinfo\t\t\t\Show information about the assignment\n"
    end
  end

  def user()
    self.common_opt
    puts " Users options:"
    print "\n\tCOMMAND\t\t\tDESCRIPTION\n\n"
    print "\torgs\t\t\tShow your organizations\n"
    self.open(USER)
    self.repos(USER)
    self.clone(USER)
    self.new_repository(USER)
    self.rm_repository(USER)
    print "\tset\t\t\tMove you to a specific repository\n"
  end

  def org()
    self.common_opt
    puts " Organization options:"
    print "\n\tCOMMAND\t\t\tDESCRIPTION\n\n"
    self.repos(ORGS)
    self.clone(ORGS)
    self.new_repository(ORGS)
    self.rm_repository(ORGS)
    self.open(ORGS)
    print "\tset\t\t\tMove you to a specific repository\n"
    self.people(ORGS)
    self.new_people_info(ORGS)
    self.assignments(ORGS)
    self.groups(ORGS)
    self.teams(ORGS)
  end

  def org_repo()
    self.common_opt
    puts " Repository options:"
    print "\n\tCOMMAND\t\t\tDESCRIPTION\n\n"
    self.info(ORGS_REPO)
    self.clone(ORGS_REPO)
    self.open(ORGS_REPO)
    print "\tcommits\t\t\tShow the list of commits from the repository\n"
    self.issues(ORGS_REPO)
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
    self.repos(TEAM)
    self.people(TEAM)
    self.clone(TEAM)
    self.open(TEAM)
    print "\tadd team member\t\tAdd a member in the team\n\n"
    print "\t\t\t\t->\tadd team member [new member]\n\n"
  end

  def user_repo()
    self.common_opt
    puts " Repository options:"
    print "\n\tCOMMAND\t\t\tDESCRIPTION\n\n"
    self.info(USER_REPO)
    self.clone(USER_REPO)
    self.open(USER_REPO)
    print "\tcommits\t\t\tShow the list of commits from the repository\n"
    self.issues(USER_REPO)
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
    self.info(ASSIG)
    print "\tadd repo\t\tAdd or create the repository of the assignment\n"
    print "\tchange repo\t\tChange a repository of the assignment\n"
    print "\t\t\t\t->\tchange repo [number of the repo]\n\n"
    print "\trm repo\t\t\tDelete a repository from the assignment list.\n"
    print "\t\t\t\t->\trm repo [id]\n\n"
    print "\tchange sufix\t\tChange a sufix from a repository of the assignment\n"
    print "\t\t\t\t->\tchange sufix [number of the repo]\n\n"
    print "\tadd group\t\tAdd a new group to the assignment\n"
    print "\trm group\t\tDelete a group from the assignment list.\n"
    print "\t\t\t\t->\trm group [name]\n\n"
    print "\t\t\t\tTo delete all the groups list, use the parameter -all.\n"
    print "\t\t\t\t->\trm group -all\n\n"
    self.open(ASSIG)
    print "\tadd students\t\tAdd new students to the assignment\n"
    print "\trm student\t\tDelete a student from the assignment list.\n"
    print "\t\t\t\t->\trm student [name]\n\n"
    print "\t\t\t\tTo delete all the students list, use the parameter -all.\n"
    print "\t\t\t\t->\trm student -all\n\n"
    print "\tmake\t\t\tCreate the repository assignment in Github for each team of every group\n\n"
  end

  def team_repo()
    self.common_opt
    puts " Repository options:"
    print "\n\tCOMMAND\t\t\tDESCRIPTION\n\n"
    self.info(TEAM_REPO)
    self.clone(TEAM_REPO)
    self.open(TEAM_REPO)
    print "\tcommits\t\t\tShow the list of commits from the repository\n"
    self.issues(TEAM_REPO)
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
    self.cd(1)
    print "\t!\t\t\tExecute a bash command\n\n"
  end

  def welcome
    puts "\nGitHub Education Shell!"
    puts "_______________________\n\n"
  end

end
