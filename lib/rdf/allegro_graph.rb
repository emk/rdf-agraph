require 'rdf'
require 'agraph'
require 'enumerator'

# AllegroGraph integration for RDF.rb.
module RDF::AllegroGraph
  autoload :Query, 'rdf/allegro_graph/query'
  autoload :Server, 'rdf/allegro_graph/server'
  autoload :Catalog, 'rdf/allegro_graph/catalog'
  autoload :AbstractRepository, 'rdf/allegro_graph/abstract_repository'
  autoload :Repository, 'rdf/allegro_graph/repository'
  autoload :SnaGenerator, 'rdf/allegro_graph/sna_generator'
  autoload :Functors, 'rdf/allegro_graph/functors'
  autoload :Parser, 'rdf/allegro_graph/parser'
  autoload :Session, 'rdf/allegro_graph/session'
end
