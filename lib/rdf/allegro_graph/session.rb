module RDF::AllegroGraph

  # A persistent AllegroGraph session.  This takes up more server resources
  # than a normal stateless repository connection, but it allows access to
  # advanced AllegroGraph features.
  #
  # Note that this class does not interoperate well with the Unix `fork`
  # command if you're using blank nodes.  See README.md for details.
  #
  # @see Repository#session
  class Session < AbstractRepository
    # Create a new session.  This parameter takes an
    # ::AllegroGraph::Repository object as an argument, so we've not going
    # to document it publically.
    #
    # @private
    def initialize(agraph_repo)
      super(::AllegroGraph::Session.create(agraph_repo))
    end
  end
end
