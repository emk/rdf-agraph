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

    # @group Paths Through the Graph

    # Search for paths between two nodes following the edges specified by
    # generator, and using a breadth-first search strategy.
    #
    # @param [Symbol,RDF::Resource] from
    #   Input: The start node in the path.
    # @param [Symbol,RDF::Resource] to
    #   Input: The end node in the path.
    # @param [PrologLiteral] generator
    #   Input: The generator to use when finding links to traverse.
    # @param [Symbol] to
    #   Output: A list of nodes in the path.
    # @param [Hash] options
    # @option options [Integer] :max_depth
    #   Input: The maxium search depth.
    # @return [void]
    def breadth_first_search_paths(from, to, generator, path, options={})
      search_paths('breadth-first-search-paths', from, to, generator, path,
                   options)
    end

    # Search for paths between two nodes following the edges specified by
    # generator, and using a depth-first search strategy.
    #
    # @param [Symbol,RDF::Resource] from
    #   Input: The start node in the path.
    # @param [Symbol,RDF::Resource] to
    #   Input: The end node in the path.
    # @param [PrologLiteral] generator
    #   Input: The generator to use when finding links to traverse.
    # @param [Symbol] to
    #   Output: A list of nodes in the path.
    # @param [Hash] options
    # @option options [Integer] :max_depth
    #   Input: The maxium search depth.
    # @return [void]
    def depth_first_search_paths(from, to, generator, path, options={})
      search_paths('depth-first-search-paths', from, to, generator, path,
                   options)
    end

    # Search for paths between two nodes following the edges specified by
    # generator, and using a bidirectional search strategy.
    #
    # @param [Symbol,RDF::Resource] from
    #   Input: The start node in the path.
    # @param [Symbol,RDF::Resource] to
    #   Input: The end node in the path.
    # @param [PrologLiteral] generator
    #   Input: The generator to use when finding links to traverse.
    # @param [Symbol] to
    #   Output: A list of nodes in the path.
    # @param [Hash] options
    # @option options [Integer] :max_depth
    #   Input: The maxium search depth.
    # @return [void]
    def bidirectional_search_paths(from, to, generator, path, options={})
      search_paths('bidirectional-search-paths', from, to, generator, path,
                   options)
    end

    # @private
    def search_paths(functor_name, from, to, generator, path, options={})
      if options.has_key?(:max_depth)
        functor(functor_name, from, to, generator,
                PrologLiteral.new(options[:max_depth]), path)
      else
        functor(functor_name, from, to, generator, path)
      end
    end


    # @group Nearby Nodes

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
    # @return [void]
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
    # @return [void]
    def ego_group_member(actor, depth, generator, member)
      functor('ego-group-member', actor, PrologLiteral.new(depth),
              generator, member)
    end    
  end
end
