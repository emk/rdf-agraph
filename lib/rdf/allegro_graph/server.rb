module RDF::AllegroGraph
  class Server
    def initialize(url="http://localhost:10035")
      parsed = URI.parse(url)
      options = {
        :host => parsed.host, :post => parsed.port,
        :username => parsed.user, :password => parsed.password
      }
      @server = AllegroGraph::Server.new(options)
      @path = parsed.path
    end

    def path(more_path=nil)
      if more_path.nil? then @path else "#{@path}/#{more_path}" end
    end

    def protocol
      @server.request_http(:get, path(:protocol),
                           :expected_status_code => 200).to_i
    end
    alias_method :protocol_version, :protocol
  end
end
