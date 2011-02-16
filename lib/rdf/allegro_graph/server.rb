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
      
      unless parsed.path.nil? || parsed.path.empty? || parsed.path == "/"
        puts parsed.path.inspect
        err = "AllegroGraph URLs with paths not supported: #{url}"
        raise ArgumentError.new(err)
      end
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
        result[repo['id']] = Repository.new(:server => self, :id => repo['id'])
      end
      result
    end

    def has_repository?(id)
      repositories.has_key?(id)
    end

    def each_repository(&block)
      repositories.values.each(&block)
    end
    alias_method :each, :each_repository

    def repository(id, options={})
      result = repositories[id]
      if result.nil? && options[:create]
        ::AllegroGraph::Repository.new(self, id).create!
        result = Repository.new(:server => self, :id => id)
      end
      result
    end
    alias_method :[], :repository
  end
end
