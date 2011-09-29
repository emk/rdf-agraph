require 'pathname'

module RDF::AllegroGraph
  # An AllegroGraph catalog containing several repositories.
  class Catalog
    attr_reader :catalog

    # Create a new Catalog object.
    #
    # @param [String] url The Sesame URL of the AllegroGraph server.
    def initialize(url_or_hash, options={})
      url_or_hash = Parser::parse_uri(url_or_hash) if url_or_hash.is_a?(String)
      server = url_or_hash[:server].server
      id = url_or_hash[:id]

      @name = id
      @catalog = AllegroGraph::Catalog.new(server, id)
      @catalog.create_if_missing! if options[:create]
    end

    # Delete this catalog if it exists.
    #
    # @return [void]
    def delete!
      @catalog.delete!
    end

    # Return a hash table of all repositories in this catalog.
    #
    # @return [Hash<String,Repository>]
    def repositories
      result = {}
      repositories = @catalog.server.request_json(:get, self.path(:repositories),
        :expected_status_code => 200).each do |repo|
        result[repo['id']] = Repository.new(:catalog => self, :id => repo['id'])
      end
      result
    end

    # Return true if the specified repository exists in the catalog.
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
        result = Repository.new({:catalog => self, :id => id}, :create => true)
      end
      result
    end
    alias_method :[], :repository

    protected

    # Generate a path to a resource on the catalog.
    def path(relativate_path=nil)
      if relativate_path
        "/catalogs/#{@name}/#{relativate_path}"
      else
        "/catalogs/#{@name}"
      end
    end

  end

end