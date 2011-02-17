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

    # Create a new, persistent AllegroGraph session.  If called without a
    # block, simply returns the new session (and expects the caller to
    # close it).  If called with a block, automatically commits or rolls
    # back the transaction, and closes the session.
    #
    # @overload session
    #   @return [Session] The newly created session.  It's a good idea to
    #     close this manually; doing so frees up server resources.
    #   @see Session#close
    #
    # @overload session
    #   @yield session
    #   @yieldparam [Session] session
    #   @yieldreturn [Object]
    #   @return [Object] The result returned from the block.
    def session
      if block_given?
        session = Session.new(@repo)
        begin
          result = yield session
          session.commit
          result
        rescue => e
          session.rollback
          raise
        ensure
          session.close
        end
      else
        Session.new(@repo)
      end
    end
  end
end
