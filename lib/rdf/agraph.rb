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
        else super
        end
      end


      #--------------------------------------------------------------------
      # RDF::Enumerable methods

      # Iterate over all statements in the repository.  This is used by
      # RDF::Enumerable as a fallback for handling any unimplemented
      # methods.
      def each(&block)
        query_pattern(RDF::Query::Pattern.new, &block)
      end

      # Does the repository contain the specified statement?
      def has_statement?(statement)
        found = @repo.statements.find(statement_to_dict(statement))
        !found.empty?
      end

      # TODO: There are lots of methods with names like 'predicates',
      # 'each_predicate', etc., that we could usefully override if anybody
      # needs to be able to list all the predicates in the repository
      # without scanning every record.  But we'll wait until somebody needs
      # those before overriding the default implementations.


      #--------------------------------------------------------------------
      # RDF::Countable methods
      #
      # TODO: I'd love to override these methods for the sake of
      # performance, but RDF.rb does not want duplicate statements to be
      # counted twice, and AllegoGraph does count them.

      # Is this repository empty?
      #def empty?
      #  count == 0
      #end

      # How many statements are in this repository?
      #def count
      #  @server.request_http(:get, "#{@repo.path}/statements",
      #                       :headers => { 'Accept' => 'text/integer' },
      #                       :expected_status_code => 200).chomp.to_i
      #end


      #--------------------------------------------------------------------
      # RDF::Queryable methods

      # Return all RDF statements matching a pattern.
      def query_pattern(pattern)
        if block_given?
          seen = {}
          dict = statement_to_dict(pattern)
          dict.delete(:context) if dict[:context] == 'null'
          @repo.statements.find(dict).each do |statement|
            unless seen.has_key?(statement)
              seen[statement] = true
              s,p,o,c = statement.map {|v| unserialize(v) }
              if c.nil?
                yield RDF::Statement.new(s,p,o)
              else
                yield RDF::Statement.new(s,p,o, :context => c)
              end
            end
          end
        else
          ::Enumerable::Enumerator.new(self, :query_pattern, pattern)
        end        
      end

      # TODO: Override first, first_subject, first_predicate, first_object,
      # first_literal for performance.


      #--------------------------------------------------------------------
      # RDF::Mutable methods

      # Insert a single statement into the repository.
      def insert_statement(statement)
        insert_statements([statement])
      end

      # Insert multiple statements at once.
      def insert_statements(statements)
        # FIXME: RDF.rb expects duplicate statements to be ignored if
        # inserted into a mutable store, but AllegoGraph allows duplicate
        # statements.  We work around this in our other methods, but we
        # need to either use transactions, find appropriate AllegroGraph
        # documentation, or talk to the RDF.rb folks.
        #
        # A discussion of duplicate RDF statements:
        # http://lists.w3.org/Archives/Public/www-rdf-interest/2004Oct/0091.html
        #
        # Note that specifying deleteDuplicates on repository creation doesn't
        # seem to affect this.
        json = statements_to_json(statements)
        @server.request_json(:post, "#{@repo.path}/statements", :body => json,
                             :expected_status_code => 204)
      end

      # Delete a single statement from the repository.
      def delete_statement(statement)
        delete_statements([statement])
      end

      # Delete multiple statements from the repository.
      def delete_statements(statements)
        json = statements_to_json(statements)
        @server.request_json(:post, "#{@repo.path}/statements/delete",
                             :body => json, :expected_status_code => 204)
      end

      # TODO: Override delete to implement fast wildcard deletion without
      # having to first query for the matching records.

      # Clear all statements from the repository.
      def clear
        @repo.statements.delete
      end

      protected

      # Convert a list of statements to a JSON-compatible array.
      def statements_to_json(statements)
        statements.map do |s|
          tuple = [s.subject, s.predicate, s.object]
          tuple << s.context if s.context
          tuple.map {|v| serialize(v) }
        end        
      end

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
