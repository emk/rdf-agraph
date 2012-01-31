module RDF::AllegroGraph
  # An AllegroGraph server containing several repositories.  We attempt to
  # mimic the public API of RDF::Sesame::Server for the sake of
  # convenience, though we do not implement several internal methods, and
  # we generally attempt to raise errors when we can't connect to the
  # server, unlike RDF::Sesame::Server, which just returns default values.
  #
  # @see RDF::Sesame::Server
  class Server
    attr_reader :server

    # Create a new Server object.
    #
    # @param [String] url The Sesame URL of the AllegroGraph server.
    def initialize(url="http://localhost:10035")
      parsed = URI.parse(url)
      options = {
        :host => parsed.host, :post => parsed.port,
        :username => parsed.user, :password => parsed.password
      }
      @server = AllegroGraph::Server.new(options)

      unless parsed.path.nil? || parsed.path.empty? || parsed.path == "/"
        err = "AllegroGraph URLs with paths not supported: #{url}"
        raise ArgumentError.new(err)
      end
    end

    # Get the protocol version supported by this server.
    #
    # @return [Integer]
    def protocol
      @server.request_http(:get, path(:protocol),
                           :expected_status_code => 200).to_i
    end
    alias_method :protocol_version, :protocol

    # Return a hash table of all repositories on this server.
    #
    # @return [Hash<String,Repository>]
    def repositories
      result = {}
      @server.request_json(:get, path(:repositories),
                           :expected_status_code => 200).each do |repo|
        result[repo['id']] = Repository.new(:server => self, :id => repo['id'])
      end
      result
    end

    # Return true if the specified repository exists on the server.
    #
    # @param [String] id The name of the repository.
    # @return [Boolean]
    def has_repository?(id)
      repositories.has_key?(id)
    end

    # Iterate over all repositories.
    #
    # @yield repository
    # @yieldparam [Repository] repository
    # @yieldreturn [void]
    # @return [void]
    def each_repository(&block)
      repositories.values.each(&block)
    end
    alias_method :each, :each_repository

    # Look up a specific repository by name, and optionally create it.
    #
    # @param [String] id The name of the repository.
    # @param [Hash] options
    # @option options [Boolean] :create
    #   If true, and the repository does not exist, create it.
    # @return [Repository,nil]
    #   The repository, if it exists or was created, or nil otherwise.
    def repository(id, options={})
      result = repositories[id]
      if result.nil? && options[:create]
        result = Repository.new({:server => self, :id => id}, :create => true)
      end
      result
    end
    alias_method :[], :repository

    # Return a hash table of all catalogs on this server.
    #
    # @return [Hash<String,Catalog>]
    def catalogs
      result = {}
      @server.request_json(:get, path(:catalogs),
                           :expected_status_code => 200).each do |catalog|
        result[catalog['id']] = Catalog.new(:server => self, :id => catalog['id'])
      end
      result
    end

    # Return true if the specified catalog exists on the server.
    #
    # @param [String] id The name of the catalog.
    # @return [Boolean]
    def has_catalog?(id)
      catalogs.has_key?(id)
    end

    # Iterate over all catalogs.
    #
    # @yield catalog
    # @yieldparam [Catalog] catalog
    # @yieldreturn [void]
    # @return [void]
    def each_catalog(&block)
      catalogs.values.each(&block)
    end

    # Look up a specific catalog by name, and optionally create it.
    #
    # @param [String] id The name of the catalog.
    # @param [Hash] options
    # @option options [Boolean] :create
    #   If true, and the catalog does not exist, create it.
    # @return [Repository,nil]
    #   The catalog, if it exists or was created, or nil otherwise.
    def catalog(id, options={})
      result = catalogs[id]
      if result.nil? && options[:create]
        result = Catalog.new({:server => self, :id => id}, :create => true)
      end
      result
    end

    # An initialization-file can be specified for a server, which is a collection of Common Lisp code
    # that is executed in every shared back-end as it is created. This retrieves that file.
    # If no initfile has been defined, nil is returned.
    #
    # @return [String] the content of the file
    def initfile
      if (content = @server.request_http(:get, '/initfile')) == "No initfile defined."
        content = nil
      end
      content
    end

    # A set of scripts, which are Common Lisp programs, can be stored in a server.
    # When a user creates a session, they can choose to load one or more of these scripts into the session.
    # This service returns a list of names, representing the scripts that are currently present.
    #
    # @param [String] path a filter on the subfolder to look scripts into
    # @return [Array] the scripts list
    def scripts(path=nil)
      full_path = "/scripts"
      full_path = "#{full_path}/#{path}" if path

      @server.request_json(:get, full_path,
                           :expected_status_code => 200)
    end

    # Get a script content
    #
    # @param [String] path the name of the script
    # @return [String] the script
    def script(path)
      full_path = "/scripts/#{path}"

      begin
        @server.request_http(:get, full_path,
                           :expected_status_code => 200)
      rescue Transport::UnexpectedStatusCodeError => error
        if /No script '[^']+' found./ =~ error.message
          nil
        else
          raise error
        end
      end
    end

    alias_method :get_script, :script

    # Replace the named script with a new one (or creates a new script).
    # Scripts whose name ends in .fasl are assumed to be compiled Lisp code (you are responsible for ensuring that it is compatible with the server),
    # anything else is assumed to be raw Common Lisp code, which the server will compile.
    #
    # @param [String] path the name of the script
    # @param [String] content the script content
    # @return [void]
    def save_script(path, content)
      full_path = "/scripts/#{path}"

      @server.request_http(:put, full_path,
                           :body => content)
    end

    # Delete the script with the given path
    #
    # @param [String] path the name of the script
    # @return [void]
    def remove_script(path)
      full_path = "/scripts/#{path}"

      @server.request_http(:delete, full_path)
    end

    protected

    # Generate a path to a resource on the server.
    def path(relativate_path) # @private
      "/#{relativate_path}"
    end
  end
end
