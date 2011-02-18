# AllegroGraph functors for use in Prolog queries.
#
# Note that we only support a few functors right now.  For a list of all
# available AllegroGraph functors, see
# <http://www.franz.com/agraph/support/documentation/v4/lisp-reference.html>.
# Adding new functors is easy; see SnaFunctors for examples.
module RDF::AllegroGraph::Functors
  autoload :SnaFunctors, 'rdf/allegro_graph/functors/sna_functors'
end
