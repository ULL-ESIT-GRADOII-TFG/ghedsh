require 'octokit'
require 'json'
require 'csv'
require 'require_all'
require_rel '.'
require 'readline'

GITHUB_LIST = %w[githubid github idgithub github_id id_github githubuser github_user].freeze
MAIL_LIST = ['email', 'mail', 'e-mail'].freeze

class Organizations
  attr_accessor :orgslist
  attr_accessor :peoplelist

  def load_people
    @peoplelist = {}
    @peoplelist = Sys.new.load_people_db("#{ENV['HOME']}/.ghedsh")
    @peoplelist
  end

  # Takes people info froma a csv file and gets into ghedsh people information
  def add_people_info(client, config, file, relation)
    list = load_people
    csvoptions = { quote_char: '|', headers: true, skip_blanks: true }
    members = get_organization_members(client, config) # members of the organization
    change = false
    indexname = ''

    inpeople = list['orgs'].detect { |aux| aux['name'] == config['Org'] }
    if inpeople.nil?
      list['orgs'].push('name' => config['Org'], 'users' => [])
      Sys.new.save_people("#{ENV['HOME']}/.ghedsh", list)
    end

    file += '.csv' if file.end_with?('.csv') == false
    if File.exist?(file)
      begin
        mem = CSV.read(file, csvoptions)
      rescue StandardError
        print 'Invalid csv format.'
      end

      fields = mem.headers
      users = {}
      users = []
      puts "\nFields found: "
      puts fields
      puts
      mem.each do |i|
        aux = {}
        fields.each do |j|
          if !i[j].nil?
            if GITHUB_LIST.include?(j.delete('"').downcase.strip)
              data = i[j]
              data = data.delete('"')
              aux['github'] = data
              j = 'github'
            else
              if MAIL_LIST.include?(j.delete('"').downcase.strip)
                aux['email'] = i[j].delete('"').strip
                indexname = j
                j = 'email'
                change = true
              else
                data = i[j].delete('"')
                aux[j.delete('"').downcase.strip] = data.strip
              end
            end
          else
            data = i[j].delete('"')
            aux[j.delete('"').downcase.strip] = data.strip
          end
        end
        users.push(aux)
      end
      ## Aqui empiezan las diferenciaa
      if relation == true
        fields[fields.index(indexname)] = 'email' if change == true
        fields = users[0].keys
        # if users.keys.include?("github") and users.keys.include?("email") and users.keys.size==2
        if fields.include?('github') && fields.include?('email') && (fields.size == 2)
          users.each do |i|
            if members.include?(i['github'].delete('"'))
              here = list['orgs'].detect { |aux| aux['name'] == config['Org'] }['users'].detect { |aux2| aux2['github'] == i['github'] } # miro si ya esta registrado
              if here.nil?
                list['orgs'].detect { |aux| aux['name'] == config['Org'] }['users'] << i
                puts "#{i['github']} information correctly added"
              else # si ya esta registrado...
                puts "#{i['github']} is already registered in this organization"
              end
            else
              puts "#{i['github']} is not registered in this organization"
            end
          end
        else
          puts 'No relationship found between github users and emails.'
          return nil
        end
      else # insercion normal, relacion ya hecha
        users.each do |i|
          here = list['orgs'].detect { |aux| aux['name'] == config['Org'] }['users'].detect { |aux2| aux2['email'] == i['email'] }
          if !here.nil?
            i.each do |j|
              list['orgs'].detect { |aux| aux['name'] == config['Org'] }['users'].detect { |aux2| aux2['email'] == i['email'] }[(j[0]).to_s] = j[1]
            end
          else
            puts "No relation found of #{i['email']} in #{config['Org']}"
          end
        end
      end
      # tocho
      Sys.new.save_people("#{ENV['HOME']}/.ghedsh", list)
    else
      print "\n#{file} file not found.\n\n"
    end
  end

  def rm_people_info(_client, config)
    list = load_people
    inpeople = list['orgs'].detect { |aux| aux['name'] == config['Org'] }
    if inpeople.nil?
      puts 'Extended information has not been added yet'
    else
      if inpeople['users'].empty?
        puts 'Extended information has not been added yet'
      else
        list['orgs'].detect { |aux| aux['name'] == config['Org'] }['users'] = []
        Sys.new.save_people("#{ENV['HOME']}/.ghedsh", list)
        puts "The aditional information of #{config['Org']} has been removed"
      end
    end
  end

  def search_rexp_people_info(_client, config, exp)
    list = load_people
    if !list.nil?
      if list['users'] != []
        list = list['orgs'].detect { |aux| aux['name'] == config['Org'] }
        if exp =~ /^\//
          sp = exp.split('/')
          exp = Regexp.new(sp[1], sp[2])
        end
        list = Sys.new.search_rexp_peoplehash(list['users'], exp)

        if list != []
          fields = list[0].keys
          list.each do |i|
            puts "\n\e[31m#{i['github']}\e[0m"
            fields.each do |j|
              puts "#{j.capitalize}:\t #{i[j]}"
            end
            puts
          end
        end
      else
        puts 'Extended information has not been added yet'
      end
    else
      list['orgs'].push('name' => config['Org'], 'users' => [])
      Sys.new.save_people("#{ENV['HOME']}/.ghedsh", list)
      puts 'Extended information has not been added yet'
    end
  end

  def show_people_info(_client, config, user)
    list = load_people

    inpeople = list['orgs'].detect { |aux| aux['name'] == config['Org'] }
    peopleinfolist = []

    if inpeople.nil?
      list['orgs'].push('name' => config['Org'], 'users' => [])
      Sys.new.save_people("#{ENV['HOME']}/.ghedsh", list)
      puts 'Extended information has not been added yet'
    else
      if inpeople['users'] != []
        if user.nil?
          fields = list['orgs'].detect { |aux| aux['name'] == config['Org'] }['users'][0].keys
          list['orgs'].detect { |aux| aux['name'] == config['Org'] }['users'].each do |i|
            puts "\n\e[31m#{i['github']}\e[0m"
            fields.each do |j|
              puts "#{j.capitalize}:\t #{i[j]}"
            end
            peopleinfolist << i['github']
          end
          return peopleinfolist
        else
          if user.include?('@')
            inuser = list['orgs'].detect { |aux| aux['name'] == config['Org'] }['users'].detect { |aux2| aux2['email'] == user }
          else
            inuser = list['orgs'].detect { |aux| aux['name'] == config['Org'] }['users'].detect { |aux2| aux2['github'] == user }
          end
          if inuser.nil?
            puts 'Not extended information has been added of that user.'
          else
            fields = inuser.keys
            puts "\n\e[31m#{inuser['github']}\e[0m"
            fields.each do |j|
              puts "#{j.capitalize}:\t #{inuser[j]}"
            end
            puts
          end
        end
      else
        puts 'Extended information has not been added yet'
      end
    end
  end

  def show_organization_members_bs(client, config)
    orgslist = []
    print "\n"
    mem = client.organization_members(config['Org'])
    mem.each do |i|
      m = eval(i.inspect)
      orgslist.push(m[:login])
      puts m[:login]
    end
    puts
    orgslist
  end

  def get_organization_members(client, config)
    mem = client.organization_members(config['Org'])
    list = []
    unless mem.nil?
      mem.each do |i|
        list << i[:login]
      end
    end
    list
  end

  def show_orgs(client, _config)
    orgslist = []
    print "\n"
    org = client.organizations
    org.each do |i|
      o = eval(i.inspect)
      puts o[:login]
      orgslist.push(o[:login])
    end
    print "\n"
    orgslist
  end

  def read_orgs(client)
    orgslist = []
    org = client.organizations
    org.each do |i|
      o = eval(i.inspect)
      orgslist.push(o[:login])
    end
    orgslist
  end

  def open_org(client, config)
    mem = client.organization(config['Org'])
    Sys.new.open_url(mem[:html_url])
  end

  def open_user_url(_client, config, user, field)
    list = load_people
    inpeople = list['orgs'].detect { |aux| aux['name'] == config['Org'] }
    found = 0

    if inpeople.nil?
      list['orgs'].push('name' => config['Org'], 'users' => [])
      Sys.new.save_people("#{ENV['HOME']}/.ghedsh", list)
      puts 'Extended information has not been added yet'
    else
      if user.downcase.start_with?('/') && (user.downcase.count('/') == 2)
        sp = user.split('/')
        exp = Regexp.new(sp[1], sp[2])
        inuser = Sys.new.search_rexp_peoplehash(list['orgs'].detect { |aux| aux['name'] == config['Org'] }['users'], exp)
        user.slice!(0); user = user.chop
      else
        inuser = []
        inuser.push(list['orgs'].detect { |aux| aux['name'] == config['Org'] }['users'].detect { |aux2| aux2['github'] == user })
      end
      if inuser.nil?
        puts 'Not extended information has been added of that user.'
      else
        if field.nil?
          inuser.each do |i|
            i.each_value do |j|
              next unless j.include?('github.com')
              if !j.include?('https://') && !j.include?('http://')
                Sys.new.open_url('https://' + j)
              else
                Sys.new.open_url(j)
              end
              found = 1
            end
          end
          if found == 0
            puts 'No github web profile in the aditional information'
          end
        else
          if inuser != []
            if field.downcase.start_with?('/') && field.downcase.end_with?('/') # #regexp
              field = field.delete('/')
              inuser.each do |i|
                next if i.nil?
                i.each_value do |j|
                  next unless j.include?(field)
                  if j.include?('https://') || j.include?('http://')
                    Sys.new.open_url(j)
                  end
                end
              end
            else
              inuser.each do |_i|
                if inuser.keys.include?(field.downcase)
                  if inuser[field.downcase].include?('https://') || inuser[field.downcase].include?('http://')
                    url = inuser[field.downcase.to_s]
                  else
                    url = 'http://' + inuser[field.downcase.to_s]
                  end
                  Sys.new.open_url(url)
                else
                  puts 'No field found with that name'
                end
              end
            end
          else
            puts 'No field found with that name'
          end
        end
      end
    end
  end
end
