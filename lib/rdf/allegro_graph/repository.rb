require 'pathname'

module RDF::AllegroGraph
  # An AllegroGraph RDF repository.
  #
  # Note that this class does not interoperate well with the Unix `fork`
  # command if you're using blank nodes.  See README.md for details.
  class Repository < AbstractRepository
    # Create a new AllegroGraph repository adapter.
    #
    # @overload initialize(options)
    #   @param [Hash{Symbol => Object}] options
    #   @option options [Server]  :server  The server hosting the repository.
    #   @option options [String]  :id      The name of the repository.
    #   @option options [Boolean] :create  Create the repository if necessary?
    #
    # @overload initialize(url, options)
    #   @param [String] url                The URL of the repository.
    #   @param [Hash{Symbol => Object}] options
    #   @option options [Boolean] :create  Create the repository if necessary?
    def initialize(url_or_options, options={})
      case url_or_options
      when String
        # TODO: Clean this up.
        url = URI.parse(url_or_options)
        path = Pathname.new(url.path)
        url.path = path.parent.parent.to_s
        server = Server.new(url.to_s).server
        id = path.basename
      else
        server = url_or_options[:server].server
        id = url_or_options[:id]
        options = url_or_options
      end
      super(::AllegroGraph::Repository.new(server, id))
      @repo.create_if_missing! if options[:create]
    end

    # Delete this repository if it exists.
    #
    # @return [void]
    def delete!
      @repo.delete!
    end

    # Create a new, persistent AllegroGraph session.  If called without a
    # block, simply returns the new session (and expects the caller to
    # close it).  If called with a block, automatically commits or rolls
    # back the transaction, and closes the session.
    #
    # @overload session
    #   @return [Session] The newly created session.  It's a good idea to
    #     close this manually; doing so frees up server resources.
    #   @see Session#commit
    #   @see Session#rollback
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
