require 'tty-prompt'
require 'tty-spinner'
require 'rainbow'

# colors:
  # error: .color('#cc0000')
  # command not found: .yellow
  # warning: .color('#9f6000')

def custom_spinner(message)
  spinner = TTY::Spinner.new(Rainbow("#{message}").color(79, 138, 16), format: :bouncing_ball)
end