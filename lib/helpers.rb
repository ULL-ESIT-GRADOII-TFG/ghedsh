require 'tty-prompt'
require 'tty-spinner'
require 'rainbow'

def custom_spinner(message)
  spinner = TTY::Spinner.new(Rainbow("#{message}").color(4,255,0), format: :bouncing_ball)
end