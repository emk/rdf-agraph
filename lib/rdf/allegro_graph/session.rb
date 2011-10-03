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
    # Create a new session.  This function takes a ::AllegroGraph::Repository or
    # a ::AllegroGraph::Server object as first argument, and options as second
    # parameter, which is optional.
    #
    # @private
    def initialize(repository_or_server, options={})
      # Use of the AllegroGraph wrapped entity
      agraph_repository_or_server = case repository_or_server
      when Repository
        repository_or_server.resource
      when Server
        repository_or_server.server
      else
        Server.new(repository_or_server.to_s).server
      end
      opt_session = options.delete(:session)
      opt_writable_mirror = options.delete(:writable_mirror)

      if opt_writable_mirror
        options[:writable_repository] =
        case opt_writable_mirror
        when Repository
          opt_writable_mirror.resource
         else
          Repository.new(opt_writable_mirror).resource
        end
      end

      super(::AllegroGraph::Session.create(agraph_repository_or_server, opt_session), options)
      @last_unique_id = 0
    end

    # Explicitly close the current session and release all server resources.
    # This function does _not_ commit any outstanding transactions.
    #
    # @return [void]
    # @see #commit
    # @see #rollback
    def close
      @resource.request_http(:post, path('session/close'),
                         :expected_status_code => 204)
    end

    # Commit the current changes to the main repository.
    #
    # @return [void]
    # @see #rollback
    def commit
      @resource.commit
    end

    # Roll back the changes made since the last commit.
    #
    # @return [void]
    # @see #commit
    def rollback
      @resource.rollback
    end

    # Let the session know you still want to keep it alive. (Any other request to the session will have the same effect.)
    #
    # @return [Boolean] returns true if the operation was sucessful
    def ping
      @resource.request_http(:get, path('session/ping'),
                         :expected_status_code => 200) == 'pong'
    end

    # Returns true if the session is still alive.
    # Basically it pings the session. If the TCP connection is refused,
    # it means that the session has been closed.
    #
    # @return [Boolean] returns the status of the session
    def still_alive?
      begin
        ping
      rescue Errno::ECONNREFUSED
        false
      end
    end

    # Define an SNA generator.
    #
    # @param [Hash] options
    # @option options [RDF::Resource,Array<RDF::Resource>] :object_of
    #   Follow links defined by specified predicates.
    # @option options [RDF::Resource,Array<RDF::Resource>] :subject_of
    #   Follow links defined by specified predicates, but from the object
    #   to the subject.
    # @option options [RDF::Resource,Array<RDF::Resource>] :undirected
    #   Follow links defined by specified predicates in both directions.
    # @return [Query::PrologLiteral]
    #   A value which may be used in Prolog queries.
    #
    # @see Query#ego_group_member
    def generator(options)
      id = unique_id
      generator = SnaGenerator.new(self, options)
      @resource.request_json(:put, path("snaGenerators/#{id}"),
                         :parameters => generator.to_params,
                         :expected_status_code => 204)
      Query::PrologLiteral.new(id.to_sym)
    end

    protected

    def unique_id
      "id#{@last_unique_id += 1}"
    end
  end
end
