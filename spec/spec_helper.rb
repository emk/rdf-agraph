# Set up bundler and require all our support gems.
require 'rubygems'
require 'bundler'
Bundler.require(:default, :development)

# Add our library directory to our require path.
$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')

# Load the entire gem through our top-level file.
require 'rdf-agraph'
