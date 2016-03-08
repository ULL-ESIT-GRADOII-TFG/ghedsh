require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "Run simple interace"
task :bash do
	sh "ruby lib/bash_tp.rb"
end
