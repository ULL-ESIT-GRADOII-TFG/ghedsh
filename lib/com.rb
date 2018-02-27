case
  when op == "exit" then ex=0
    @sysbh.save_memory(config_path,@config)
    s.save_cache(config_path,@config)
    s.remove_temp("#{ENV['HOME']}/.ghedsh/temp")
  when op.include?("help") && opcd[0]=="help" then self.help(opcd)
  when op == "orgs" then self.orgs()
  when op == "cd .."
    if @deep==ORGS then t.clean_groupsteams() end ##cleans groups cache
    self.cdback(false)
  when op.include?("cd assig") && opcd[0]=="cd" && opcd[1]=="assig" && opcd.size==3
    if @deep==ORGS
      self.cdassig(opcd[2])
    end
  when op == "people" then self.people()
  when op == "teams"
    if @deep==ORGS
      t.show_teams_bs(@client,@config)
    end
  when op == "commits" then self.commits()
  when op == "issues"
    if @deep==ORGS_REPO || @deep==USER_REPO || @deep==TEAM_REPO
      @issues_list=r.show_issues(@client,@config,@deep)
    end
  when op == "col" then self.collaborators()
  when op == "forks" then self.show_forks()
  when op == "groups"
    if @deep==ORGS
      t.list_groups(@client,@config)
      @sysbh.add_history_str(2,t.get_groupslist(@config))
    end
  when op.include?("group") && opcd[0]=="group"
    if opcd.size==2
      teams=t.get_single_group(@config,opcd[1])
      if teams!=nil
        puts "Teams in group #{opcd[1]} :"
        puts teams
      else
        puts "Group not found"
      end
    end
  when op.include?("new") && opcd[0]=="new" && opcd[1]=="team"        #new's parse
    if opcd.size==3 and @deep==ORGS
      t.create_team(@client,@config,opcd[2])
      @teamlist=t.read_teamlist(@client,@config)
      @sysbh.add_history_str(1,@teamlist)
    end
    if opcd.size>3 and @deep==ORGS
      t.create_team_with_members(@client,@config,opcd[2],opcd[3..opcd.size])
      @teamlist=t.read_teamlist(@client,@config)
      @sysbh.add_history_str(1,@teamlist)
    end
  when op.include?("new") && !op.include?("comment") && opcd[0]=="new" && opcd[1]=="issue"
    if opcd.size==2 and (@deep==ORGS_REPO || @deep==USER_REPO || @deep==TEAM_REPO)
      r.create_issue(@client,@config,@deep,config_path)
    end
  when op.include?("new") && (opcd[0]=="new" && opcd[1]=="issue" && opcd[2]=="comment")
    if opcd.size==4 and (@deep==ORGS_REPO || @deep==USER_REPO || @deep==TEAM_REPO)
      r.add_issue_cm(@client,@config,@deep,opcd[3],config_path)
    end
  when op.include?("new") && opcd[0]=="new" && opcd[1]=="people" && opcd[2]=="info"
    if @deep==ORGS  && opcd.size==4 then o.add_people_info(@client,@config,opcd[3],false) end
  when op.include?("new") && opcd[0]=="new" && opcd[1]=="repository"
    if opcd.size==3
      r.create_repository(@client,@config,opcd[2],false,@deep)
    end
  when op.include?("new relation") && opcd[0]=="new" && opcd[1]="relation"
    if opcd.size==3 and @deep==ORGS
      o.add_people_info(@client,@config,opcd[2],true)
    end
  when op.include?("new assignment") && opcd[0]=="new" && opcd[1]="assignment"
    if opcd.size==3 and @deep==ORGS
        r.create_repository_by_teamlist(@client,@config,opcd[2],opcd[3,opcd.size],self.get_teamlist(opcd[3,opcd.size]))
        o.create_assig(@client,@config,opcd[2])
        @sysbh.add_history(opcd[2])
    end
  when op.include?("new group") && opcd[0]=="new" && opcd[1]="group"
    if opcd.size==5 and @deep==ORGS and opcd[2]=="-f"
      t.new_group_file(@client,@config,opcd[3],opcd[4])
    end
    if opcd.size>3 and @deep==ORGS and !op.include?("-f")
       t.new_group(@client,@config,opcd[2],opcd[3..opcd.size-1])
    end

  when op.include?("rm team") && opcd[0]=="rm" && opcd[1]="team"            ##rm parse
    if opcd.size==3
      @teamlist=t.read_teamlist(@client,@config)
      if @teamlist[opcd[2]]!=nil
        t.delete_team(@client,@teamlist[opcd[2]])
        @sysbh.quit_history(@teamlist[opcd[2]])
        @teamlist=t.read_teamlist(@client,@config)
        @sysbh.add_history_str(1,@teamlist)
      else
        puts "Team not found"
      end
    end

  when op.include?("rm group") && opcd[0]=="rm" && opcd[1]="group"
    if opcd.size==3 and @deep==ORGS
      t.delete_group(@config,opcd[2])
    end
    if opcd.size==3 and @deep==ASSIG
      if opcd[2]!="-all"
        o.rm_assigment_group(@config,@config["Assig"],opcd[2],1)
      else
        o.rm_assigment_group(@config,@config["Assig"],opcd[2],2)
      end
    end
  when op.include?("rm student") && opcd[0]=="rm" && opcd[1]="student"
    if opcd.size==3 and @deep==ASSIG
      if opcd[2]!="-all"
        o.rm_assigment_student(@config,@config["Assig"],opcd[2],1)
      else
        o.rm_assigment_student(@config,@config["Assig"],opcd[2],2)
      end
    end
  when op.include?("rm repository") && opcd[0]=="rm" && opcd[1]="repository"
    if @deep==ORGS || @deep==USER || @deep==TEAM
      r.delete_repository(@client,@config,opcd[2],@deep)
      if @deep==ORGS
        @orgs_repos.delete(opcd[2])
      end
    end
  when op.include?("rm repo")&& opcd[0]=="rm" && opcd[1]="repo"
    if @deep==ASSIG and opcd.size==3
      o.rm_assigment_repo(@config,@config["Assig"],opcd[2])
    end
  when op.include?("rm clone files") && opcd[0]=="rm" && opcd[1]="clone" && opcd[2]="files"
    if opcd.size>3
      r.rm_clone(@client,@config,@scope,false,opcd[3])
    else
      r.rm_clone(@client,@config,@scope,true,nil)
    end
  when op == "info"
    if @deep==ASSIG then o.show_assig_info(@config,@config["Assig"]) end
    if @deep==USER_REPO || @deep==TEAM_REPO || @deep==ORGS_REPO then r.info_repository(@client,@config,@deep) end
  when op== "add repo"
    if @deep==ASSIG then o.add_repo_to_assig(@client,@config,@config["Assig"],nil) end
  when op.include?("change repo") && opcd[0]=="change" && opcd[1]=="repo"
    if @deep==ASSIG
      if opcd.size>2
        o.add_repo_to_assig(@client,@config,@config["Assig"],opcd[2])
      else
        o.add_repo_to_assig(@client,@config,@config["Assig"],1)
      end
    end
  when op.include?("change sufix") && opcd[0]=="change" && opcd[1]=="sufix"
    if @deep==ASSIG
      if opcd.size>2 then o.change_repo_sufix(@config,@config["Assig"],opcd[2]) end
    end
  when op=="add students" && @deep==ASSIG
     o.add_people_to_assig(@client,@config,@config["Assig"])
  when op.include?("rm")
    if @deep==ORGS and opcd[1]=="people" and opcd[2]=="info"
      o.rm_people_info(@client,@config)
    end
  when op== "add group"
      if @deep=ASSIG then o.add_group_to_assig(@client,@config,@config["Assig"]) end
  when op == "version"
    puts "GitHub Education Shell v#{Ghedsh::VERSION}"

  when op.include?("add team member") && opcd[0]=="add" && opcd[1]="team" && opcd[2]="member"
    if opcd.size==4 and @deep==TEAM
      t.add_to_team(@client,@config,opcd[3])
    end

  when op.include?("close issue") && opcd[0]=="close" && opcd[1]="issue"
    if (@deep==ORGS_REPO || @deep==USER_REPO || @deep==TEAM_REPO) and opcd.size==3
      r.close_issue(@client,@config,@deep,opcd[2])
    end

  when op.include?("open issue") && opcd[0]=="open" && opcd[1]="issue"
    if (@deep==ORGS_REPO || @deep==USER_REPO || @deep==TEAM_REPO) and opcd.size==3
      r.open_issue(@client,@config,@deep,opcd[2])
    end

  when op == "assignments"
    if @deep==ORGS
      o.show_assignments(@client,@config)
      @sysbh.add_history_str(2,o.get_assigs(@client,@config,false))
    end
  when op =="make"
    if @deep==ASSIG
      o.make_assig(@client,@config,@config["Assig"])
    end
  when op.include?("open") && opcd[0]=="open"
    if @deep==USER_REPO || @deep==TEAM_REPO || @deep==ORGS_REPO then r.open_repository(@client,@config,@deep) end
    if @deep==USER then u.open_user(@client) end
    if @deep==ORGS
      if opcd.size==1
        o.open_org(@client,@config)
      else
        if opcd.size==2
          o.open_user_url(@client,@config,opcd[1],nil)
        else
          o.open_user_url(@client,@config,opcd[1],opcd[2])
        end
      end
    end
    if @deep==TEAM then t.open_team_repos(@config) end
    if @deep==ASSIG then o.open_assig(@config,@config["Assig"]) end
end

if opcd[0]=="issue" and opcd.size>1
  if @deep==ORGS_REPO || @deep==USER_REPO || @deep==TEAM_REPO
    r.show_issue(@client,@config,@deep,opcd[1])
  end
end

if opcd[0]=="cd" and opcd[1]!=".."
  if opcd[1]=="/" or opcd.size==1
    self.cdback(true)
  else
    if opcd[1]=="repo" and opcd.size>2
      self.set(opcd[2])
    else
      if opcd[1].include?("/")
        cdlist=opcd[1].split("/")
        cdlist.each do |i|
          opscript.push("cd #{i}")
        end
      else
        self.cd(opcd[1])
      end
    end
  end
end
if opcd[0]=="do" and opcd.size>1
  opscript=s.load_script(opcd[1])
end
if opcd[0]=="set"
  self.set(opcd[1])
end
if opcd[0]=="repos" and opcd.size==1
  self.repos(false)
end
if opcd[0]=="repos" and opcd.size>1         ##Busca con expresion regular, si no esta en la cache realiza la consulta
  if opcd[1]=="-all" || opcd[1]=="-a"
    self.repos(true)
  else
    case
    when @deep==USER
      if @repos_list.empty?
        r.show_repos(@client,@config,@deep,opcd[1])
        @repos_list=r.get_repos_list(@client,@config,@deep)
      else
        @sysbh.showcachelist(@repos_list,opcd[1])
      end
    when @deep==ORGS
      if @orgs_repos.empty?
        r.show_repos(@client,@config,@deep,opcd[1])
        @orgs_repos=r.get_repos_list(@client,@config,@deep)
      else
        @sysbh.showcachelist(@orgs_repos,opcd[1])
      end
    when @deep==TEAM
      if @teams_repos.empty?
        r.show_repos(@client,@config,@deep,opcd[1])
        @teams_repos=r.get_repos_list(@client,@config,@deep)
      else
        @sysbh.showcachelist(@teams_repos,opcd[1])
      end
    end
  end
end

if opcd[0]=="private" and opcd.size==2
  if opcd[1]=="true" || opcd[1]=="false"
    r.edit_repository(@client,@config,@deep,opcd[1])
  end
end

if opcd[0]=="people" and opcd[1]=="info"
  if opcd.size==2
    info_strm=o.show_people_info(@client,@config,nil)
    if info_strm!=nil then @sysbh.add_history_str(2,info_strm) end
  else
    if opcd[2].include?("/")
      o.search_rexp_people_info(@client,@config,opcd[2])
    else
      o.show_people_info(@client,@config,opcd[2])
    end
  end
end
if opcd[0]=="clone"
  if opcd.size==2
    r.clone_repo(@client,@config,opcd[1],@deep)
  end
  if opcd.size==1 && (@deep==USER_REPO || @deep==TEAM_REPO || @deep==ORGS_REPO)
    r.clone_repo(@client,@config,nil,@deep)
  end
  if opcd.size==1 && deep==ASSIG
    r.clone_repo(@client,@config,"/#{@config["Assig"]}/",@deep)
    puts "/#{@config["Assig"]}/"
  end
end
if op.match(/^!/)
  op=op.split("!")
  s.execute_bash(op[1])
end
if opcd[0]=="clone" and opcd.size>2
    #r.clone_repo(@client,@config,opcd[1])
end
if opcd[0]=="files"
  if opcd.size==1
    r.get_files(@client,@config,@repo_path,true,@deep)
  else
    r.get_files(@client,@config,opcd[1],true,@deep)
  end
end
if opcd[0]=="cat" and opcd.size>1
  r.cat_file(@client,@config,opcd[1],@deep)
end
end
