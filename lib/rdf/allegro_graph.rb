# AllegroGraph integration for RDF.rb.
module RDF::AllegroGraph
  autoload :Query, 'rdf/allegro_graph/query'
  autoload :Server, 'rdf/allegro_graph/server'
  autoload :AbstractRepository, 'rdf/allegro_graph/abstract_repository'
  autoload :Repository, 'rdf/allegro_graph/repository'
  autoload :Session, 'rdf/allegro_graph/session'
end
