# This code is based on http://blog.datagraph.org/2010/04/rdf-repository-howto

module RDF
  module AllegroGraph
    class Repository < RDF::Repository
      def initialize(options)
        repository = options[:repository]
        server_options = options.dup
        server_options.delete(:repository)
        @server = ::AllegroGraph::Server.new(server_options)
        @repo = ::AllegroGraph::Repository.new(@server, repository)
        @repo.create_if_missing!        
        @blank_nodes_local_to_server = {}
        @blank_nodes_server_to_local = {}
      end

      def each
        if block_given?
          @repo.statements.find.each do |statement|
            s,p,o,c = statement.map {|v| unserialize(v) }
            if c.nil?
              yield RDF::Statement.new(s,p,o)
            else
              yield RDF::Statement.new(s,p,o,c)
            end
          end
        else
          ::Enumerable::Enumerator.new(self, :each)
        end
      end

      def insert_statement(statement)
        @repo.statements.create(serialize(statement.subject),
                                serialize(statement.predicate),
                                serialize(statement.object),
                                serialize(statement.context))
      end

      def delete_statement(statement)
        @repo.statements.delete(statement_to_dict(statement))
      end

      def has_statement?(statement)
        found = @repo.statements.find(statement_to_dict(statement))
        !found.empty?
      end

      def clear
        @repo.statements.delete
      end

      protected

      def statement_to_dict(statement)
        {
          :subject => serialize(statement.subject),
          :predicate => serialize(statement.predicate),
          :object => serialize(statement.object),
          :context => serialize(statement.context)
        }
      end

      # Return true if this a blank RDF node.
      def blank_node?(node)
        !node.nil? && node.anonymous?
      end

      # Allocate an "official" AllegroGraph blank node, which should
      # maintain its identity across requests.
      def allocate_blank_node
        response = @server.request_http(:post, "#{@repo.path}/blankNodes",
                                        :parameters => { :amount => 1 },
                                        :expected_status_code => 200)
        response.chomp.gsub(/^_:/, '')
      end

      def map_blank_node(local_id, server_id)
        #puts "Mapping #{local_id} -> #{server_id}"
        @blank_nodes_local_to_server[local_id] = server_id
        @blank_nodes_server_to_local[server_id] = local_id
      end

      def map_to_server(node)
        return node unless blank_node?(node)
        unless @blank_nodes_local_to_server.has_key?(node.id)
          new_id = allocate_blank_node
          map_blank_node(node.id, new_id)
        end
        RDF::Node.new(@blank_nodes_local_to_server[node.id])
      end

      def map_from_server(node)
        return node unless blank_node?(node)
        if @blank_nodes_server_to_local.has_key?(node.id)
          RDF::Node.new(@blank_nodes_server_to_local[node.id])
        else
          # We didn't generate this node ID, so we want to pass it back to
          # the server unchanged.
          map_blank_node(node.id, node.id)
          node
        end
      end

      def serialize(node)
        RDF::NTriples::Writer.serialize(map_to_server(node))
      end

      def unserialize(node)
       map_from_server(RDF::NTriples::Reader.unserialize(node))
      end
    end
  end
end
