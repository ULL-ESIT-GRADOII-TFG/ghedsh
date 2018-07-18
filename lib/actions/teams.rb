require 'readline'
require 'octokit'
require 'json'
require 'require_all'

class Team
  attr_accessor :teamlist; :groupsteams
  
  def self.shell_prompt(config)
    if config['Repo'].nil?
      Rainbow("#{config['User']}> ").aqua << Rainbow("#{config['Org']}> ").magenta << Rainbow("#{config['Team']}> ").color('#eeff41')
    else
      Rainbow("#{config['User']}> ").aqua + Rainbow("#{config['Org']}> ").magenta << Rainbow("#{config['Team']}> ").color('#eeff41') << Rainbow("#{config['Repo']}> ").color(236, 151, 21)
    end
  end

  def build_cd_syntax(type, name)
    syntax_map = { 'repo' => "Team.new.cd('repo', #{name}, client, env)" }
    unless syntax_map.key?(type)
      raise Rainbow("cd #{type} currently not supported.").color('#cc0000')
    end
    syntax_map[type]
  end

  def open_info(config, params = nil, client = nil)
    if config['Repo'].nil?
      open_url(config['team_url'].to_s)
    else
      open_url(config['repo_url'].to_s)
    end
  end
end
