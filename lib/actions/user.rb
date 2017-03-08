require 'readline'
require 'octokit'
require 'json'
require 'require_all'
require_rel '.'

class User
  def info(client)
    mem=client.user(client.login)
    puts m[:login]
    puts m[:name]
    puts m[:email]
  end

  def open_user(client)
    mem=client.user(client.login)
    case
    when RUBY_PLATFORM.downcase.include?("darwin")
      system("open #{mem[:html_url]}")
    when RUBY_PLATFORM.downcase.include?("linux")
      system("xdg-open #{mem[:html_url]}")
    end
  end
end
