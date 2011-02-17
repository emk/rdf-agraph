module RDF::AllegroGraph::Functors
  
  # This module contains AllegroGraph functor definitions that may be
  # called when building a query.  Note that these functors merely add a
  # functor expression to a query.  The actual functor will be called on
  # the server.
  #
  # @see Session#generator
  module SnaFunctors
    # @private
    PrologLiteral = RDF::AllegroGraph::Query::PrologLiteral

    # Generate an actor's ego group.
    #
    # @param [Symbol,RDF::Resource] actor
    #   Input: The resource at the center of the graph.
    # @param [Integer] depth
    #   Input: The maximum number of links to traverse.
    # @param [PrologLiteral] generator
    #   Input: The generator to use when finding links to traverse.
    # @param [Array<RDF::Resource>] group
    #   Output: Either a variable or resource.
    def ego_group(actor, depth, generator, group)
      functor('ego-group', actor, PrologLiteral.new(depth),
              generator, group)
    end

    # Generate all members of an actor's ego group.
    #
    # @param [Symbol,RDF::Resource] actor
    #   Input: The resource at the center of the graph.
    # @param [Integer] depth
    #   Input: The maximum number of links to traverse.
    # @param [PrologLiteral] generator
    #   Input: The generator to use when finding links to traverse.
    # @param [Symbol,RDF::Resource] group
    #   Input/Output: Either a variable or resource.
    #
    # @see Session#generator
    def ego_group_member(actor, depth, generator, member)
      functor('ego-group-member', actor, PrologLiteral.new(depth),
              generator, member)
    end    
  end
end
