require 'octokit'
require 'json'
require 'csv'
require 'require_all'
require_rel '.'
require 'readline'

class Assignment
  attr_accessor :assiglist

  def load_assig
    @assiglist = {}
    @assiglist = Sys.new.load_assig_db("#{ENV['HOME']}/.ghedsh")
    @assiglist
  end

  def show_assignments(_client, config) # client,orgs
    list = load_assig

    assig = list['orgs'].detect { |aux| aux['name'] == config['Org'] }
    if !assig.nil?
      if assig['assigs'].empty?
        puts 'No assignments are available yet'
      else
        assig['assigs'].each do |i|
          puts "\n"
          puts i['name_assig']
          i.each { |key, value| if key.include?('repo') then puts "Repository #{key.delete('repo')}: #{value}" end }
          if (i['groups'] != []) && !i['groups'].nil?
            puts "\tGroups: "
            i['groups'].each do |y|
              puts "\t\t#{y}"
            end
          end
          if (i['people'] != []) && !i['people'].nil?
            puts "\tStudents: "
            i['people'].each do |y|
              puts "\t\t#{y}"
            end
            puts "\n"
          end
          print "\n"
        end
      end
    else
      puts 'No assignments are available yet'
      list['orgs'].push('name' => config['Org'], 'assigs' => [])
      Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh", list)
    end
  end

  def assignment_repository(client, config, name)
    ex = false
    until ex == true
      puts "\n"
      puts "Assignment: #{name}"
      puts '1) Add a repository already created '
      puts '2) Create a new empty repository'
      puts "3) Don't assign a repository yet"
      print 'option => '
      op = gets.chomp
      puts "\n"
      ex = true if (op == '1') || (op == '2') || (op == '3')
    end
    if op == '1' || op == '2'

      if op == '1'
        ex2 = false
        until ex2 == true
          exname = false
          until exname == true
            puts 'Name of the repository -> Owner/Repository or Organization/Repository :'
            reponame = gets.chomp
            if (reponame.split('/').size != 2) && (reponame != '')
              puts 'Please introduce a valid format.'
            else
              exname = true
            end
            if reponame == ''
              exname = true
              ex2 = true
            end
          end
          if reponame != ''
            if client.repository?(reponame.to_s) == false
              puts "\e[31m The repository #{reponame} doesn't exist\n \e[0m"
              puts "\nName of the repository (To skip and add the repository later, only press enter): "
              ex2 = true if reponame == ''
            else
              ex2 = true
            end
          end
        end
      end
      if op == '2'
        ex2 = false
        until ex2 == true
          puts 'Name of the repository (To skip and add the repository later, press enter): '
          reponame = gets.chomp
          if reponame == ''
            ex2 = true
          else
            # ex2=Repositories.new().create_repository(client,config,reponame,false,ORGS)
            if client.repository?("#{config['Org']}/#{reponame}")
              puts "\e[31m Already exists a repository with that name in #{config['Org']}\e[0m"
            else
              reponame = "#{config['Org']}/#{reponame}"
              ex2 = true
            end
          end
        end
      end
    elsif op == '3' then reponame = ''
    end
    reponame
  end

  def assignment_groups(client, config)
    team = Teams.new
    sys = Sys.new
    groupslist = team.get_groupslist(config)
    groupsadd = []
    teamlist = team.read_teamlist(client, config)

    puts "\n"
    puts "Groups currently available:\n\n"
    groupslist.each do |aux|
      puts "\t#{aux}"
    end

    puts "\nAdd groups to your assignment (Press enter to skip): "
    op = gets.chomp
    if op == ''
      puts 'Do you want to create a new group? (Press any key and enter to proceed, or only enter to skip)'
      an = gets.chomp

      if an != ''
        time = Time.new
        puts "Put the name of the group (If you skip with enter, the group's name will be \"Group-#{time.ctime}\")"
        name = gets.chomp
        if name == ''
          name = "Group-#{time.ctime}"
          name = name.split(' ').join('-')
        end
        puts "\nTeams currently available:\n\n"
        teamlist.each do |aux|
          puts "\t#{aux[0]}"
        end
        begin
          puts "\n1)Put a list of Teams"
          puts '2)Take all the Teams available'
          puts "3)Take the teams from a file\n"
          puts '4)Add the teams to the group later'
          print 'option => '
          op2 = gets.chomp
        end while (op2 != '1' && op2 != '2' && op2 != '3' && op2 != '4')
        refuse = false # para no añadirlo cuando se niege en la repeticion de la busqueda de fichero
        if op2 == '1'
          puts "\nPut a list of Teams (Separeted with space): "
          list = gets.chomp
          list = list.split(' ')
        end
        if op2 == '2'
          puts 'All the teams have been taken'
          list = teamlist.keys
        end
        if op2 == '3'
          begin
            ex = 2
            puts 'Put the name of the file: '
            file = gets.chomp
            list = sys.loadfile(file)
            if list.nil?
              puts "The file doesn't exist or It's empty. Do you like to try again? (y/n):"
              op3 = gets.chomp
              if (op3 == 'n') || (op3 == 'N')
                ex = 1
                refuse = true
              end
            else
              ex = 1
            end
          end while ex != 1
        end
        if (op != '4') && (refuse == false)
          team.new_group(client, config, name, list)
        end
        groupsadd.push(name)
      else
        groupsadd = []
      end

    else
      groupsadd = op.split(' ')
      groupsadd.each do |item|
        groupsadd.delete(item) if groupslist.detect { |aux| aux == item }.nil?
      end
    end
    groupsadd
  end

  def assignment_people(client, config)
    refuse = false
    members = get_organization_members(client, config)
    sys = Sys.new
    begin
      puts "\n1)Put a list of students"
      puts '2)Take all the list'
      puts "3)Take the students from a file\n"
      puts '4)Add the students later'
      print 'option => '
      op2 = gets.chomp
    end while (op2 != '1' && op2 != '2' && op2 != '3' && op2 != '4')
    if op2 == '1'
      puts members
      puts "\nPut a list of students (Separeted with space): "
      list = gets.chomp
      list = list.split(' ')
    end
    if op2 == '2'
      puts 'All the students have been taken'
      list = members
    end
    if op2 == '3'
      begin
        ex = 2
        puts 'Put the name of the file: '
        file = gets.chomp
        list = sys.loadfile(file)
        if list.nil?
          puts "The file doesn't exist or It's empty. Do you like to try again? (y/n):"
          op3 = gets.chomp
          if (op3 == 'n') || (op3 == 'N')
            ex = 1
            refuse = true
          end
        else
          ex = 1
        end
      end while ex != 1
    end
    if (op2 != 4) && (refuse == false)
      if op2 != 2
        unless list.nil?
          list.each do |i|
            list.delete(i) unless members.include?(i)
          end
        end
      end
      return list
    else
      return []
    end
  end

  def create_assig(client, config, name)
    list = load_assig
    assigs = list['orgs'].detect { |aux| aux['name'] == config['Org'] }

    if assigs.nil?
      list['orgs'].push('name' => config['Org'], 'assigs' => [])
      Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh", list)
    end

    assig_exist = list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux| aux['name_assig'] == name }
    if assig_exist.nil?
      begin
        puts "\n1)Individual assignment"
        puts '2)Group assignment'
        puts '3)Discard assignment'
        print 'option => '
        op = gets.chomp
      end while op != '1' && op != '2' && op != '3'

      if op != '3'
        reponame = assignment_repository(client, config, name)
        if op == '2'
          groupsadd = assignment_groups(client, config)
          peopleadd = []
        end
        if op == '1'
          peopleadd = assignment_people(client, config)
          groupsadd = []
        end
        begin
          list['orgs'][list['orgs'].index { |aux| aux['name'] == config['Org'] }]['assigs'].push('name_assig' => name, 'teams' => [], 'people' => peopleadd, 'groups' => groupsadd, 'repo' => reponame)
        rescue Exception => e
          puts e
        end
        Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh", list)
      end
    else
      puts 'Already exists an Assignment with that name'
    end
  end

  def get_assigs(_client, config, show)
    list = load_assig
    assiglist = []
    assig = list['orgs'].detect { |aux| aux['name'] == config['Org'] }
    if !assig.nil?
      if assig['assigs'].empty?
        puts "\e[31m No assignments are available yet\e[0m" if show == true
      else
        assig['assigs'].each do |i|
          assiglist.push(i['name_assig'])
        end
      end
    else
      list['orgs'].push('name' => config['Org'], 'assigs' => [])
      Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh", list)
    end
    assiglist
  end

  def get_single_assig(config, wanted)
    list = load_assig
    as = list['orgs'].detect { |aux| aux['name'] == config['Org'] }
    as = as['assigs'].detect { |aux| aux['name_assig'] == wanted }
    as
  end

  def show_assig_info(config, assig)
    assig = get_single_assig(config, assig)
    team = Teams.new
    puts "\n"
    puts assig['name_assig']
    assig = assig.sort.to_h
    assig.each { |key, value| if key.include?('repo') then puts "Repository #{key.delete('repo')}: #{value}" end }
    puts
    assig.each { |key, value| if key.include?('sufix') then puts "Sufix of Repository #{key.delete('sufix')} : #{value}" end }
    print "\n"
    if assig['groups'] != []
      puts "\tGroups: "
      assig['groups'].each do |y|
        puts "\t\t#{y}"
        t = team.get_single_group(config, y)
        next if t.nil?
        t.each do |z|
          puts "\t\t\t#{z}"
        end
      end
    end
    if (assig['people'] != []) && !assig['people'].nil?
      puts "\tStudents: "
      assig['people'].each do |y|
        puts "\t\t#{y}"
      end
      puts "\n"
    end
  end

  def make_assig(client, config, assig)
    web = 'https://github.com/'
    web2 = 'git@github.com:'
    r = Repositories.new
    team = Teams.new
    sys = Sys.new
    teamlist = team.read_teamlist(client, config)
    assig = get_single_assig(config, assig)
    repolist = []
    point = 1
    assig.each { |key, value| repolist.push(value) if key.include?('repo') }

    if repolist != []
      repolist.each do |repo|
        sys.create_temp("#{ENV['HOME']}/.ghedsh/temp")
        puts repo
        if repolist.size > 1
          if point > 1 || assig.key?('sufix1')
            sufix = "sufix#{point}"
            sufix = "-#{assig[sufix.to_s]}"
          else
            sufix = ''
          end
        else
          sufix = ''
        end
        point += 1
        unless client.repository?(repo)
          aux = repo.split('/')
          aux = aux[1]
          r.create_repository(client, config, aux, false, ORGS)
        end
        system("git clone #{web2}#{repo}.git #{ENV['HOME']}/.ghedsh/temp/#{repo}")
        if assig['groups'] != []
          assig['groups'].each do |i|
            teamsforgroup = team.get_single_group(config, i)
            next if teamsforgroup.nil?
            teamsforgroup.each do |y|
              config['TeamID'] = teamlist[y.to_s]
              config['Team'] = y
              puts y
              puts sufix
              r.create_repository(client, config, "#{assig['name_assig']}#{sufix}-#{y}", true, TEAM)
              system("git -C #{ENV['HOME']}/.ghedsh/temp/#{repo} remote rm origin")
              system("git -C #{ENV['HOME']}/.ghedsh/temp/#{repo} remote add origin #{web2}#{config['Org']}/#{assig['name_assig']}#{sufix}-#{y}.git")

              system("git -C #{ENV['HOME']}/.ghedsh/temp/#{repo} push origin --all")
            end
          end
        end
        next unless (assig['people'] != []) && !assig['people'].nil?
        assig['people'].each do |i|
          r.create_repository(client, config, "#{assig['name_assig']}#{sufix}-#{i}", true, ORGS)
          system("git -C #{ENV['HOME']}/.ghedsh/temp/#{repo} remote rm origin")
          system("git -C #{ENV['HOME']}/.ghedsh/temp/#{repo} remote add origin #{web2}#{config['Org']}/#{assig['name_assig']}#{sufix}-#{i}.git")
          system("git -C #{ENV['HOME']}/.ghedsh/temp/#{repo} push origin --all")
          r.add_collaborator(client, "#{config['Org']}/#{assig['name_assig']}#{sufix}-#{i}", i)
        end
      end
    else
      puts "\e[31m No repository is given for this assignment\e[0m"
    end
  end

  def add_team_to_assig(_client, config, assig, _data)
    assig = get_single_assig(config, assig)
  end

  def add_people_to_assig(client, config, assig)
    list = load_assig
    people = assignment_people(client, config)
    if list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux2| aux2['name_assig'] == assig }['people'].nil?
      list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux2| aux2['name_assig'] == assig }['people'] = []
    end

    if people != ''
      people.each do |i|
        if !list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux2| aux2['name_assig'] == assig }['people'].include?(i)
          list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux2| aux2['name_assig'] == assig }['people'].push(i)
        else
          puts "#{i} is already in this assignment."
        end
      end
      Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh", list)
    end
  end

  def add_group_to_assig(client, config, assig)
    list = load_assig

    groups = assignment_groups(client, config)
    if groups != ''
      groups.each do |i|
        list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux2| aux2['name_assig'] == assig }['groups'].push(i)
      end
      Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh", list)
    end
  end

  def open_assig(config, assig)
    Sys.new.open_url("https://github.com/search?q=org%3A#{config['Org']}+#{assig}")
  end

  def add_repo_to_assig(client, config, assig, change)
    list = load_assig
    notexist = false

    if !change.nil? # change an specific repository
      reponumber = change
      fields = list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux2| aux2['name_assig'] == assig }.keys
      if reponumber == '1'
        notexist = true unless fields.include?('repo')
      else
        notexist = true unless fields.include?('repo' + change.to_s)
      end
    else # adding new repository
      fields = list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux2| aux2['name_assig'] == assig }.keys
      reponumber = 1
      ex = 0
      while ex == 0
        if reponumber == 1
          if fields.include?('repo')
            reponumber += 1
          else
            ex = 1
          end
        else
          if fields.include?("repo#{reponumber}")
            reponumber += 1
          else
            ex = 1
          end
        end
      end
    end

    if notexist == true
      puts "Doesn't exist that repository"
    else
      reponame = assignment_repository(client, config, assig['name_assig'])
      if reponumber.to_i > 1
        sufix = "sufix#{reponumber}"
        sufixname = assignment_repo_sufix(reponumber, 1)
      end
    end

    if (reponame != '') && (notexist == false)
      if reponumber.to_i == 1
        list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux2| aux2['name_assig'] == assig }['repo'] = reponame
        Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh", list)
      else
        list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux2| aux2['name_assig'] == assig }["repo#{reponumber}"] = reponame
        list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux2| aux2['name_assig'] == assig }[sufix.to_s] = sufixname
        Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh", list)
      end
    end
  end

  def rm_assigment_repo(config, assig, reponumber)
    list = load_assig

    if reponumber == 1
      if list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux2| aux2['name_assig'] == assig }['repo'] != nil
        list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux2| aux2['name_assig'] == assig }.delete('repo')
        list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux2| aux2['name_assig'] == assig }.delete('sufix1')
        Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh", list)
      else
        puts "Doesn't exist that repository"
      end
    else
      if list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux2| aux2['name_assig'] == assig }["repo#{reponumber}"] != nil
        list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux2| aux2['name_assig'] == assig }.delete("repo#{reponumber}")
        list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux2| aux2['name_assig'] == assig }.delete("sufix#{reponumber}")
        Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh", list)
      else
        puts "Doesn't exist that repository"
      end
    end
  end

  def rm_assigment_student(config, assig, student, mode)
    list = load_assig
    if mode == 1
      if list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux2| aux2['name_assig'] == assig }['people'].include?(student)
        list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux2| aux2['name_assig'] == assig }['people'].delete(student)
        puts "Student #{student} correctly deleted from the assignment"
        Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh", list)
      else
        puts 'Student not found'
      end
    else
      list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux2| aux2['name_assig'] == assig }['people'].clear
      puts 'All the students has been deleted from the assignment'
      Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh", list)
    end
  end

  def rm_assigment_group(config, assig, group, mode)
    list = load_assig
    if mode == 1
      if list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux2| aux2['name_assig'] == assig }['groups'].include?(group)
        list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux2| aux2['name_assig'] == assig }['groups'].delete(group)
        puts "Group #{group} correctly deleted from the assignment"
        Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh", list)
      else
        puts 'Group not found'
      end
    else
      list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux2| aux2['name_assig'] == assig }['groups'].clear
      puts 'All the groups has been deleted from the assignment'
      Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh", list)
    end
  end

  def assignment_repo_sufix(reponumber, order)
    op = ''
    print "\n"
    if order == 1
      while (op == '') || (op == "\n")
        puts "Add the suffix of the repository \"#{reponumber}\", in order to differentiate it from the other repositories: "
        op = gets.chomp
      end
    else
      while (op == '') || (op == "\n")
        puts 'Add the suffix of the first repository, in order to differentiate it from the other repositories: '
        op = gets.chomp
      end
    end
    op
  end

  def change_repo_sufix(config, assig, reponumber)
    list = load_assig
    if list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux2| aux2['name_assig'] == assig }["sufix#{reponumber}"] != nil
      if reponumber == 1
        sufixname = assignment_repo_sufix(reponumber, 2)
        sufix = 'sufix1'
      else
        sufixname = assignment_repo_sufix(reponumber, 1)
        sufix = "sufix#{reponumber}"
      end

      list['orgs'].detect { |aux| aux['name'] == config['Org'] }['assigs'].detect { |aux2| aux2['name_assig'] == assig }[sufix.to_s] = sufixname
      Sys.new.save_assigs("#{ENV['HOME']}/.ghedsh", list)
    else
      puts "Doesn't exist a repository with that identifier"
    end
  end
end
