module RDF::AllegroGraph
  # A module containg the URL parser of AllegroGraph objects such as :
  # - servers
  # - catalogs
  # - repositories
  module Parser

    # Parse a full URI and extract the server/catalog and the repository ID.
    #
    # The parsing uses the default AllegroGraph URI schema :
    # http://server:port/catalogs/catalog_name/repositories/repository_name
    # This function can be overwritten to parse a custom URI schema system.
    #
    # @param [String] uri the uri the parse
    # @return [Array]
    def parse_uri(url)
      hash = {}
      url = URI.parse(url)
      path = Pathname.new(url.path)

      hash[:id] = path.basename.to_s
      path = path.parent.parent
      url.path = path.to_s

      if path.parent.basename.to_s == 'catalogs'
        hash[:catalog] = Catalog.new(url.to_s)
      else
        hash[:server] = Server.new(url.to_s)
      end

      hash
    end
    module_function :parse_uri
  end
end