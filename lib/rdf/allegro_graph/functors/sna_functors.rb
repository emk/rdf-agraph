module RDF::AllegroGraph::Functors
  
  # This module contains AllegroGraph functor definitions that may be
  # called when building a query.  Note that these functors merely add a
  # functor expression to a query.  The actual functor will be called on
  # the server.
  module SnaFunctors
    # @private
    PrologLiteral = RDF::AllegroGraph::Query::PrologLiteral

    # Generate all members of an actor's ego group.
    #
    # @param [RDF::Resource] actor The resource at the center of the graph.
    # @param [Integer] depth The maximum number of links to traverse.
    # @param [PrologLiteral] generator
    #   The generator to use when finding links to traverse.
    # @param [RDF::Query::Variable,RDF::Resource] member
    #   Either a
    #
    # @see Session#generator
    def ego_group_member(actor, depth, generator, member)
      functor('ego-group-member', actor, PrologLiteral.new(depth),
              generator, member)
    end    
  end
end
