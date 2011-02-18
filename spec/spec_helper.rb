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
  :server => RDF::AllegroGraph::Server.new("http://test:test@localhost:10035"),
  :id => 'rdf_agraph_test'
}
REPOSITORY_OPTIONS[:server].repository("rdf_agraph_test", :create => true)

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
