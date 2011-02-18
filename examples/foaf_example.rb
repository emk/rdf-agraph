require 'rubygems'
gem 'rdf-agraph'
require 'rdf-agraph'

# Connect to our repository.
url = "http://user:passwd@localhost:10035/repositories/example"
repo = RDF::AllegroGraph::Repository.new(url, :create => true)

# Define some useful RDF vocabularies.
FOAF = RDF::FOAF  # Standard "friend of a friend" vocabulary.
EX = RDF::Vocabulary.new("http://example.com/")

# Insert a records describing several people.
repo.insert(
  # Information about Sam.
  [EX.sam,     RDF.type,   FOAF.Person],
  [EX.sam,     FOAF.name,  'Sam Smith'],
  [EX.sam,     FOAF.mbox,  'mailto:sam@example.com'],

  # Information about Susan.
  [EX.susan,   RDF.type,   FOAF.Person],
  [EX.susan,   FOAF.name,  'Susan Jones'],

  # Some more people so we have a nice graph.
  [EX.rachel,  RDF.type,   FOAF.Person],
  [EX.richard, RDF.type,   FOAF.Person],
  [EX.mike,    RDF.type,   FOAF.Person],

  # Who knows who?
  [EX.sam,     FOAF.knows, EX.susan],
  [EX.susan,   FOAF.knows, EX.rachel],
  [EX.susan,   FOAF.knows, EX.richard],
  [EX.rachel,  FOAF.knows, EX.mike],
  [EX.sam,     FOAF.knows, EX.richard]
)

# Query for all records about Susan.
puts "Things we know about Susan"
repo.query(:subject => EX.susan) do |statement|
  puts "  #{statement}"
end

# Open up a session so we can run more advanced queries.  This will require
# you to enable to following two permissions for 'user'.
#
#   [x] Start sessions
#   [x] Evaluate arbitrary code 
repo.session do |session|
  # Create a generator.
  knows = session.generator(:object_of => FOAF.knows)

  # Find everybody within two degrees of Sam.
  puts "Everybody within two degrees of Sam"
  session.build_query do |q|
    q.ego_group_member EX.sam, 2, knows, :person
  end.run do |solution|
    puts "  #{solution.person}"
  end

  # Find a path from Sam to Richard.
  puts "Paths from Sam to Mike"
  session.build_query do |q|
    q.breadth_first_search_paths EX.sam, EX.mike, knows, :path
  end.run do |solution|
    puts "  Found path:"
    solution.path.each {|p| puts "    #{p}" }
  end
end

# Erase our example data.
repo.clear
