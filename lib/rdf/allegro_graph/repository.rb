module RDF::AllegroGraph
  # An AllegroGraph RDF repository.
  #
  # Note that this class does not interoperate well with the Unix `fork`
  # command if you're using blank nodes.  See README.md for details.
  class Repository < RDF::Repository
    # This code is based on
    # http://blog.datagraph.org/2010/04/rdf-repository-howto
    #
    # For comparison purposes, here's a list of other RDF::Repository
    # implementations:
    #
    # https://github.com/fumi/rdf-4store/blob/master/lib/rdf/four_store/repository.rb
    # https://github.com/bendiken/rdf-bert/blob/master/lib/rdf/bert/client.rb
    # https://github.com/bendiken/rdf-cassandra/blob/master/lib/rdf/cassandra/repository.rb (more complete than many)
    # https://github.com/bhuga/rdf-do/blob/master/lib/rdf/do.rb
    # https://github.com/pius/rdf-mongo/blob/master/lib/rdf/mongo.rb
    # https://github.com/njh/rdf-redstore/blob/master/lib/rdf/redstore/repository.rb
    # https://github.com/bendiken/rdf-sesame/blob/master/lib/rdf/sesame/repository.rb
    # https://github.com/bhuga/rdf-talis/blob/master/lib/rdf/talis/repository.rb
    # https://github.com/bendiken/sparql-client/blob/master/lib/sparql/client/repository.rb
    #
    # We actually stack up pretty well against this list.


    #--------------------------------------------------------------------
    # @group RDF::Repository methods

    # Create a new AllegroGraph repository adapter.
    #
    # @param [Hash{Symbol => Object}] options
    # @option options [String]  :host ("localhost") Repository host.
    # @option options [Integer] :port (10035)       Repository port.
    # @option options [String]  :username (nil)     Log in as username.
    # @option options [String]  :password (nil)     Log in with password.
    # @option options [String]  :repository         Name of the repository.
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

    # Returns true if `feature` is supported.
    #
    # @param [Symbol] feature
    # @return [Boolean]
    def supports?(feature)
      case feature.to_sym
      when :context then true
      else super
      end
    end


    #--------------------------------------------------------------------
    # @group RDF::Transaction support
    #
    # TODO: Implement before_execute and after_execute.  Note that
    # RDF::Transaction can only operate on a single graph at a time.  The
    # RDF.rb transaction API is still pretty weak, and it is expected to
    # be refined over the course of the RDF.rb 0.3.x series.
    #
    # Or should we implement the methods described here?
    # http://blog.datagraph.org/2010/12/rdf-for-ruby It's not clear how
    # we should tackle this.


    #--------------------------------------------------------------------
    # @group RDF::Enumerable methods

    # Iterate over all statements in the repository.  This is used by
    # RDF::Enumerable as a fallback for handling any unimplemented
    # methods.
    #
    # @yield [statement]
    # @yieldparam [RDF::Statement] statement
    # @yieldreturn [void]
    # @return [void]
    def each(&block)
      query_pattern(RDF::Query::Pattern.new, &block)
    end

    # Does the repository contain the specified statement?
    #
    # @param [RDF::Statement] statement
    # @return [Boolean]
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
    # @group RDF::Countable methods
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
    # @group RDF::Queryable methods

    # Find all RDF statements matching a pattern.
    #
    # @overload query_pattern(pattern) {|statement| ... }
    #   @yield statement
    #   @yieldparam [RDF::Statement] statement
    #   @yieldreturn [void]
    #   @return [void]
    #
    # @overload query_pattern(pattern)
    #   @return [Enumerator]
    #
    # @param [RDF::Query::Pattern] pattern A simple pattern to match.
    # @return [void]
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
    protected :query_pattern

    # TODO: Override first, first_subject, first_predicate, first_object,
    # first_literal for performance.

    # Run an RDF::Query on the server.
    #
    # @param [RDF::Query] query The query to execute.
    # @yield solution
    # @yieldparam [RDF::Query::Solution] solution
    # @yieldreturn [void]
    #
    # @see    RDF::Queryable#query
    # @see    RDF::Query#execute
    def query_execute(query)
      # Make sure the query is valid.
      # TODO: Remove this once validate! is merged and released, and we
      # have a dependency on the appropriate version of the 'rdf' gem.
      query.validate! if query.respond_to?(:validate!)
      @repo.query.language = :sparql
      query_result = @repo.query.perform(query_to_sparql(query))
      json_to_query_solutions(query_result).each {|s| yield s }
    end
    protected :query_execute

    #--------------------------------------------------------------------
    # @group RDF::Mutable methods

    # Insert a single statement into the repository.
    #
    # @param [RDF::Statement] statement
    # @return [void]
    def insert_statement(statement)
      insert_statements([statement])
    end
    protected :insert_statement

    # Insert multiple statements at once.
    #
    # @param [Array<RDF::Statement>] statements
    # @return [void]
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
    protected :insert_statements

    # Delete a single statement from the repository.
    #
    # @param [RDF::Statement] statement
    # @return [void]
    def delete_statement(statement)
      # TODO: Do we need to handle invalid statements here by turning them
      # into queries and deleting all matching statements?
      delete_statements([statement])
    end
    protected :delete_statement

    # Delete multiple statements from the repository.
    #
    # @param [Array<RDF::Statement>] statements
    # @return [void]
    def delete_statements(statements)
      json = statements_to_json(statements)
      @server.request_json(:post, "#{@repo.path}/statements/delete",
                           :body => json, :expected_status_code => 204)
    end
    protected :delete_statements

    # TODO: Override delete to implement fast wildcard deletion without
    # having to first query for the matching records.

    # Clear all statements from the repository.
    #
    # @return [void]
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
      case node
      when RDF::Query::Variable then node.to_s
      else RDF::NTriples::Writer.serialize(map_to_server(node))
      end
    end

    # Deserialize an RDF::Node received from the server.
    def unserialize(node)
      map_from_server(RDF::NTriples::Reader.unserialize(node))
    end

    # Convert a query to SPARQL.
    def query_to_sparql(query)
      variables = []
      patterns = []
      query.patterns.each do |p|
        p.variables.each do |v|
          variables << v[1] unless variables.include?(v[1])
        end
        triple = [p.subject, p.predicate, p.object]
        str = triple.map {|v| serialize(v) }.join(" ")
        # TODO: Wrap in graph block for context!
        if p.optional?
          str = "OPTIONAL { #{str} }"
        end
        patterns << "#{str} ."
      end
      "SELECT #{variables.join(" ")}\nWHERE {\n  #{patterns.join("\n  ")} }"
    end

    # Convert a JSON query solution to a list of RDF::Query::Solution
    # objects.
    def json_to_query_solutions(json)
      names = json['names'].map {|n| n.to_sym }
      json['values'].map do |match|
        hash = {}
        names.each_with_index do |name, i|
          # TODO: I'd like to include nil values, too, but
          # RDF::Query#execute does not yet do so, so we'll filter them for
          # now.
          hash[name] = unserialize(match[i]) unless match[i].nil?
        end
        RDF::Query::Solution.new(hash)
      end      
    end

    # Return true if this a blank RDF node.
    def blank_node?(node)
      !node.nil? && node.anonymous?
    end

    # Ask AllegroGraph to generate a series of blank node IDs.
    def generate_blank_nodes(amount)
      response = @server.request_http(:post, "#{@repo.path}/blankNodes",
                                      :parameters => { :amount => amount },
                                      :expected_status_code => 200)
      response.chomp.split("\n").map {|i| i.gsub(/^_:/, '') }
    end

    # Allocate an "official" AllegroGraph blank node, which should
    # maintain its identity across requests.
    def allocate_blank_node
      if @blank_nodes.empty?
        @blank_nodes = generate_blank_nodes(@blank_nodes_to_generate).reverse
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
