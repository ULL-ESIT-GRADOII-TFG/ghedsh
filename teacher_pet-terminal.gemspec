Gem::Specification.new do |s|
 s.name = 'Teachers_pet-Terminal'
 s.version = '1.0.0'
 s.description = ""
 s.authors = ["Javier Clemente"]
 s.email = 'nookstyle@gmail.com'
 s.files = ["lib/"]
 s.homepage = ''
 s.require_paths = ['lib']
 s.required_ruby_version = '>= 1.9.3'
 s.add_dependency 'octokit', '~> 3.3'
 s.add_dependency 'require_all', '~> 1.3.2'
 s.add_development_dependency 'rake'
 s.add_development_dependency 'bundler', '~> 1.5'
end
