# Set up bundler and require all our support gems.
require 'rubygems'
require 'bundler'
Bundler.require(:default, :development)

# Add our library directory to our require path.
$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')

# Load the entire gem through our top-level file.
require 'rdf-agraph'

# Options that we use to connect to a repository.
REPOSITORY_OPTIONS = {
  :id => 'rdf_agraph_test',
  :url => 'http://test:test@localhost:10035'
}
server = RDF::AllegroGraph::Server.new(REPOSITORY_OPTIONS[:url])
server.repository(REPOSITORY_OPTIONS[:id], :create => true)
REPOSITORY_OPTIONS[:server] = server

CATALOG_REPOSITORY_OPTIONS = {
  :id => 'rdf_agraph_test',
  :catalog_id => 'catalog_rdf_agraph_test'
}

begin
  catalog = server.catalog(CATALOG_REPOSITORY_OPTIONS[:catalog_id], :create => true)
  catalog.repository(CATALOG_REPOSITORY_OPTIONS[:id], :create => true)
  CATALOG_REPOSITORY_OPTIONS[:catalog] = catalog
  CATALOG_REPOSITORY_OPTIONS[:server] = server
rescue
  puts "---------------------------"
  puts "Error : Your AllegroGraph server must be configured with the directive 'DynamicCatalogs'."
  puts "Without it, dynamic creation of catalogs using HTTP is not possible."
  puts "See http://www.franz.com/agraph/support/documentation/current/daemon-config.html#DynamicCatalogs"
  puts "---------------------------"
  exit
end

# RDF vocabularies.
FOAF = RDF::FOAF
EX = RDF::Vocabulary.new("http://example.com/")

# Load our shared examples.
require 'shared_abstract_repository_examples'

# Work around an annoying Ruby 1.8 / Ruby 1.9 incompatibility.  We don't
# actually alias Enumerator into the top-level namespace, because we
# want our tests to run in a pristine environment.
def enumerator_class
  if defined?(Enumerator)
    Enumerator
  else
    Enumerable::Enumerator
  end
end
