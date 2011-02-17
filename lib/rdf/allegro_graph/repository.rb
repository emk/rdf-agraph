module RDF::AllegroGraph
  # An AllegroGraph RDF repository.
  #
  # Note that this class does not interoperate well with the Unix `fork`
  # command if you're using blank nodes.  See README.md for details.
  class Repository < AbstractRepository
    # Create a new AllegroGraph repository adapter.
    #
    # @param [Hash{Symbol => Object}] options
    # @option options [Server]  :server  The server hosting the repository.
    # @option options [String]  :id      The name of the repository.
    def initialize(options)
      server = options[:server].server
      super(::AllegroGraph::Repository.new(server, options[:id]))
    end

    # Create a new, persistent AllegroGraph session.
    #
    # @return [Session]
    def session
      Session.new(@repo)
    end
  end
end
