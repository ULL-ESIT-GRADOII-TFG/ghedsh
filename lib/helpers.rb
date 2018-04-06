require 'tty-prompt'
require 'tty-spinner'
require 'rainbow'

# colors:
  # error: .color('#cc0000')
  # command not found: .yellow
  # warning: .color('#9f6000')
  # info: .color(#00529B)

def custom_spinner(message)
  spinner = TTY::Spinner.new(Rainbow("#{message}").color(79, 138, 16), format: :bouncing_ball)
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