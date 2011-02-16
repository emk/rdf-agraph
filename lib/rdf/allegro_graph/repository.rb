module RDF::AllegroGraph
  # An AllegroGraph RDF repository.
  class Repository < AbstractRepository


    #--------------------------------------------------------------------
    # @group RDF::Repository methods

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

    protected
  end
end
