require 'tty-prompt'
require 'tty-spinner'
require 'rainbow'
require 'fileutils'
require 'rbconfig'

# colors:
# error: .color('#cc0000')
# command not found: .yellow
# warning: .color('#9f6000')
# info: .color(#00529B)
# success: .color(79, 138, 16)

def custom_spinner(message)
  spinner = TTY::Spinner.new(Rainbow(message.to_s).color(79, 138, 16), format: :bouncing_ball)
end

def show_matching_items(item, pattern)
  occurrences = 0
  item.each do |i|
    if pattern.match(i)
      puts i
      occurrences += 1
    end
  end
  occurrences
end

def build_regexp_from_string(string)
  str = string.gsub(/\//, '')
  pattern = Regexp.new(str)
end

def repo_creation_guide
  puts Rainbow("Select 'Default' to create a quick public repo.").color('#f18973')
  puts Rainbow("Select 'Custom' for private/public repo whith specific options.").color('#f18973')
  puts Rainbow('To skip any option just hit Enter (Default options).').color('#f18973')
  puts
  choices = %w[Default Custom]
  prompt = TTY::Prompt.new
  answer = prompt.select('Select configuration', choices)
  if answer == 'Default'
    return answer
  else
    puts Rainbow('Answer questions with yes/true or no/false').color('#f18973')
    custom_options = prompt.collect do
      key(:private).ask('(Private repo? (Default: false) [yes/true, no/false]', convert: :bool)
      key(:description).ask('Write description of the repo')
      key(:has_issues).ask('Has issues? (Default:false) [yes/true, no/false]', convert: :bool)
      key(:has_wiki).ask('Has wiki? (Default: true) [yes/true, no/false]', convert: :bool)
      key(:auto_init).ask('Create an initial commit with empty README? (Default: false) (if you want .gitignore template must be yes/true)',
                          convert: :bool)
      key(:gitignore_template).ask('Desired language or platform for .gitignore template')
    end
    return custom_options.compact!
  end
end

def select_member(config, pattern, client)
  members = []
  members_url = {}
  client.organization_members(config['Org'].to_s).each do |member|
    if pattern.match(member[:login].to_s)
      members << member[:login]
      members_url[member[:login]] = member[:html_url]
    end
  end
  if members.empty?
    puts Rainbow("No member matched with #{pattern.source} inside organization #{config['Org']}").color('#9f6000')
    puts
  else
    prompt = TTY::Prompt.new
    answer = prompt.select('Select desired organization member', members)
  end
  members_url[answer]
end

def perform_git_clone(https_url)
  FileUtils.mkdir_p("#{Dir.home}/ghedsh_cloned")
  FileUtils.cd("#{Dir.home}/ghedsh_cloned") do
    https_url.each do |i|
      system("git clone --progress #{i}")
    end
  end
rescue StandardError => exception
  puts Rainbow(exception.message.to_s).color('#cc0000')
  puts
end

def open_url(url)
  os = RbConfig::CONFIG['host_os']
  if os.downcase.include?('linux')
    system("xdg-open #{url}")
  elsif os.downcase.include?('darwin')
    system("open #{url}")
  end
end
