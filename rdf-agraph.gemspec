# This is based on https://github.com/bendiken/rdf/blob/master/.gemspec
Gem::Specification.new do |gem|
  gem.version = File.read('VERSION').chomp
  gem.date = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name = 'rdf-agraph'
  gem.homepage = "http://rdf-agraph.rubyforge.org/"
  gem.license = 'Public Domain' if gem.respond_to?(:license)
  gem.summary = "AllegroGraph adapter for RDF.rb"
  gem.description = "An AllegroGraph adapter for use with RDF.rb."
  gem.rubyforge_project = 'rdf-agraph'

  gem.authors = ['Eric Kidd']
  gem.email = 'rdf-agraph@kiddsoftware.com'

  gem.platform = Gem::Platform::RUBY
  gem.files = %w(AUTHORS README.md UNLICENSE VERSION) + Dir.glob('lib/**/*.rb')
  #gem.bindir = %q(bin)
  #gem.executables = %w()
  gem.require_paths = %w(lib)
  gem.has_rdoc = false

  gem.required_ruby_version = '>= 1.8.7'

  gem.add_runtime_dependency 'rdf', '~> 1.0'
  gem.add_runtime_dependency 'agraph', '~> 0.2'
  gem.add_runtime_dependency 'json',   '~> 1.7'

  gem.add_development_dependency 'rdf-spec',  '~> 1.0'
  gem.add_development_dependency 'yard',      '~> 0.8'
  gem.add_development_dependency 'rspec',     '~> 2.12.0'
  gem.add_development_dependency 'rake',      '~> 10.0.0'
  gem.add_development_dependency 'dotenv',      '~> 0.5'
end
