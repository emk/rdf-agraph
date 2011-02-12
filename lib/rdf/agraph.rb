# This code is based on http://blog.datagraph.org/2010/04/rdf-repository-howto

module RDF
  module AllegroGraph
    # An AllegroGraph RDF repository.
    class Repository < RDF::Repository


      #--------------------------------------------------------------------
      # RDF::Repository methods

      def initialize(options)
        repository = options[:repository]
        server_options = options.dup
        server_options.delete(:repository)
        @server = ::AllegroGraph::Server.new(server_options)
        @repo = ::AllegroGraph::Repository.new(@server, repository)
        @repo.create_if_missing!
        @blank_nodes = []
        @blank_nodes_to_generate = 8
        @blank_nodes_local_to_server = {}
        @blank_nodes_server_to_local = {}
      end

      def supports?(feature)
        case feature.to_sym
        when :context then true
        else false
        end
      end


      #--------------------------------------------------------------------
      # RDF::Enumerable methods

      # Iterate over all statements in the repository.  This is used by
      # RDF::Enumerable as a fallback for handling any unimplemented
      # methods.
      def each
        if block_given?
          @repo.statements.find.each do |statement|
            s,p,o,c = statement.map {|v| unserialize(v) }
            if c.nil?
              yield RDF::Statement.new(s,p,o)
            else
              yield RDF::Statement.new(s,p,o, :context => c)
            end
          end
        else
          ::Enumerable::Enumerator.new(self, :each)
        end
      end

      # Does the repository contain the specified statement?
      def has_statement?(statement)
        found = @repo.statements.find(statement_to_dict(statement))
        !found.empty?
      end


      #--------------------------------------------------------------------
      # RDF::Mutable methods

      # Insert a single statement into the repository.
      def insert_statement(statement)
        # FIXME: RDF.rb expects duplicate statements to be ignored if
        # inserted into a mutable store, but AllegoGraph allows duplicate
        # statements.  We can't leave this as, because it's subject to race
        # conditions.  We need to either use transactions, find appropriate
        # AllegroGraph documentation, or talk to the RDF.rb folks.
        unless has_statement?(statement)
          @repo.statements.create(serialize(statement.subject),
                                  serialize(statement.predicate),
                                  serialize(statement.object),
                                  serialize(statement.context))
        end
      end

      # Delete a single statement from the repository.
      def delete_statement(statement)
        @repo.statements.delete(statement_to_dict(statement))
      end

      # Clear all statements from the repository.
      def clear
        @repo.statements.delete
      end

      protected

      # Translate a RDF::Statement into a dictionary the we can pass
      # directly to the 'agraph' gem.
      def statement_to_dict(statement)
        {
          :subject => serialize(statement.subject),
          :predicate => serialize(statement.predicate),
          :object => serialize(statement.object),
          # We have to pass the null context explicitly if we only want
          # to operate a single statement.  Otherwise, we will operate
          # on all matching s,p,o triples regardless of context.
          :context => serialize(statement.context) || 'null'
        }
      end

      # Serialize an RDF::Node for transmission to the server.
      def serialize(node)
        RDF::NTriples::Writer.serialize(map_to_server(node))
      end

      # Deserialize an RDF::Node received from the server.
      def unserialize(node)
       map_from_server(RDF::NTriples::Reader.unserialize(node))
      end

      # Return true if this a blank RDF node.
      def blank_node?(node)
        !node.nil? && node.anonymous?
      end

      # Ask AllegroGraph to generate a series of blank node IDs.
      def genetate_blank_nodes(amount)
        response = @server.request_http(:post, "#{@repo.path}/blankNodes",
                                        :parameters => { :amount => amount },
                                        :expected_status_code => 200)
        response.chomp.split("\n").map {|i| i.gsub(/^_:/, '') }
      end

      # Allocate an "official" AllegroGraph blank node, which should
      # maintain its identity across requests.
      def allocate_blank_node
        if @blank_nodes.empty?
          @blank_nodes = genetate_blank_nodes(@blank_nodes_to_generate).reverse
          @blank_nodes_to_generate *= 2
        end
        @blank_nodes.pop
      end

      # Create a mapping between a local blank node ID and a server-side
      # blank node ID.
      def map_blank_node(local_id, server_id)
        #puts "Mapping #{local_id} -> #{server_id}"
        @blank_nodes_local_to_server[local_id] = server_id
        @blank_nodes_server_to_local[server_id] = local_id
      end

      # Translate this node to a server-specific representation, taking
      # care to handle blank nodes correctly.
      def map_to_server(node)
        return node unless blank_node?(node)
        unless @blank_nodes_local_to_server.has_key?(node.id)
          new_id = allocate_blank_node
          map_blank_node(node.id, new_id)
        end
        RDF::Node.new(@blank_nodes_local_to_server[node.id])
      end

      # Translate this node to a client-specific representation, taking
      # care to handle blank nodes correctly.
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
    end
  end
end
