# This is based on https://github.com/bendiken/rdf/blob/master/.gemspec
Gem::Specification.new do |gem|
  gem.version = File.read('VERSION').chomp
  gem.date = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name = 'rdf-agraph'
  #gem.homepage = 
  gem.license = 'Public Domain' if gem.respond_to?(:license)
  gem.summary = "AllegroGraph adapter for RDF.rb"
  gem.description = "An AllegroGraph adapter for use with RDF.rb."
  #gem.rubyforge_project =
  
  gem.authors = ['Eric Kidd']
  gem.email = 'rdf-agraph@kiddsoftware.com'

  gem.platform = Gem::Platform::RUBY
  gem.files = %w(AUTHORS README.md UNLICENSE VERSION) + Dir.glob('lib/**/*.rb')
  #gem.bindir = %q(bin)
  #gem.executables = %w()
  gem.require_paths = %w(lib)
  gem.has_rdoc = false
  
  gem.required_ruby_version = '>= 1.8.7'

  gem.add_runtime_dependency 'rdf',    '~> 0.3.1'
  gem.add_runtime_dependency 'agraph', '~> 0.1.4'
  # This should be pulled in by agraph, but it isn't.
  gem.add_runtime_dependency 'json',   '>= 0.5.1'

  gem.add_development_dependency 'rdf-spec', '~> 0.3.1'
  gem.add_development_dependency 'yard',     '>= 0.6.0'
  gem.add_development_dependency 'rspec',    '>= 2.5.0'
  gem.add_development_dependency 'rcov',     '>= 0.9.9'
  gem.add_development_dependency 'rake',     '>= 0.8.7'
end
