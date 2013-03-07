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
    #   @option options [Catalog] :catalog  The catalog hosting the repository.
    #   @option options [String]  :id      The name of the repository.
    #   @option options [Boolean] :create  Create the repository if necessary?
    #
    # @overload initialize(url, options)
    #   @param [String] url                The URL of the repository.
    #   @param [Hash{Symbol => Object}] options
    #   @option options [Boolean] :create  Create the repository if necessary?
    def initialize(url_or_hash, options={})
      url_or_hash = Parser::parse_uri(url_or_hash) if url_or_hash.is_a?(String)

      if url_or_hash.has_key?(:catalog)
        server_or_catalog = url_or_hash[:catalog].catalog
      elsif url_or_hash.has_key?(:server)
        server_or_catalog = url_or_hash[:server].server
      else
        raise ArgumentError.new('Server or Catalog required')
      end

      id = url_or_hash[:id]
      opt_create = options.delete(:create)
      super(::AllegroGraph::Repository.new(server_or_catalog, id), options)
      @resource.create_if_missing! if opt_create
    end

    # Delete this repository if it exists.
    #
    # @return [void]
    def delete!
      @resource.delete!
    end

    # Create a new, persistent AllegroGraph session on a given repository.
    # If called without a block, simply returns the new session (and expects
    # the caller to close it).  If called with a block, automatically commits
    # or rolls back the transaction, and closes the session.
    #
    # @overload session
    #   @param [Repository] the repository on which to open the session
    #   @return [Session] The newly created session.  It's a good idea to
    #     close this manually; doing so frees up server resources.
    #   @see Session#commit
    #   @see Session#rollback
    #   @see Session#close
    #
    # @overload session
    #   @param [Repository] the repository on which to open the session
    #   @yield session
    #   @yieldparam [Session] session
    #   @yieldreturn [Object]
    #   @return [Object] The result returned from the block.
    def self.session(repository, options={})
      if block_given?
        session = Session.new(repository, options)
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
        Session.new(repository, options)
      end
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
    def session(options={}, &block)
      self.class.session self, &block
    end
  end
end
