module RDF::AllegroGraph
  class Server
    attr_reader :server # @private

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

    def repositories
      result = {}
      @server.request_json(:get, path(:repositories),
                           :expected_status_code => 200).each do |repo|
        result[repo['id']] = repository(repo['id'])
      end
      result
    end

    def repository(id)
      Repository.new(:server => self, :id => id)
    end
    alias_method :[], :repository
  end
end
