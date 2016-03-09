
class HelpM

  def user()
    self.common_opt
    print "orgs => show your organizations\n"
    print "repos => list your repositories\n\n"
    print "set => move you to a specific repository\n"

  end

  def org()
    self.common_opt
    print "repos => list the repositories of your organization\n"
    print "set => move you to a specific repository\n"
    print "members => members of a organization\n"
    print "teams => teams of a organization\n"
    print "delete_team => delete a team in you organization. Expected the name of the team\n"
    print "create_team => create a team in the organization. Expected the name of the team, and/or members given one by one\n\n"
  end

  def org_repo()
    self.common_opt
    print "commits => show the list of commits from the repository\n"
    print "col => show the list of collaborators from the repository\n\n"
  end

  def orgs_teams()
    self.common_opt
    print "members => members of the team\n"
    print "add_to_team => add a member in the team\n\n"
  end

  def user_repo()
    self.common_opt
    print "commits => show the list of commits from the repository\n"
    print "col => show the list of collaborators from the repository\n\n"
  end

  def common_opt()
    puts "\nList of commands.\n"
    print "exit => exit from this program\n"
    print "help => list of commands available\n"
    print "cd => go to the path\n"
  end

  def welcome
    puts "\nTeachers-Pet Terminal!"
    puts "______________________\n\n"
  end
end
