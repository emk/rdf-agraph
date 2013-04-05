module RDF::AllegroGraph
  # Features shared by regular AllegroGraph repositories and by persistent
  # backend sessions.
  #
  # Note that this class does not interoperate well with the Unix `fork`
  # command if you're using blank nodes.  See README.md for details.
  class AbstractRepository < RDF::Repository
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

    attr_reader :resource, :resource_writable
    attr_reader :query_options, :insert_options

    AUTH_QUERY_OPTIONS = [ :limit, :infer, :offset ]
    AUTH_INSERT_OPTIONS = [ :context, :continueOnError, :commit ]

    #--------------------------------------------------------------------
    # @group RDF::Repository methods

    # Create a new AllegroGraph repository adapter.
    #
    # @param [AllegroGraph::Resource] resource
    #   The underlying 'agraph'-based implementation to wrap.
    # @private
    def initialize(resource, options={})
      @resource = resource
      @resource_writable = options[:writable_repository] || resource
      @blank_nodes = []
      @blank_nodes_to_generate = 8
      @blank_nodes_local_to_server = {}
      @blank_nodes_server_to_local = {}
      self.query_options = options[:query]
      self.insert_options = options[:insert]
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

    # Set the global query options that will be used at each request.
    # Current supported options are :offset, :limit and :infer.
    #
    # @param [Hash] options the options to set
    #
    # http://www.franz.com/agraph/support/documentation/current/http-protocol.html#get-post-repo
    def query_options=(options)
      @query_options = filter_query_options(options)
    end

    # Set the global insert options that will be used at each POST request.
    # Current supported options are :context, :continueOnError, :commit.
    #
    # @param [Hash] options the options to set
    #
    # http://www.franz.com/agraph/support/documentation/current/http-protocol.html#put-post-statements
    def insert_options=(options)
      options||={}
      @format = options.delete(:format) || :json
      @insert_options = filter_insert_options(options)
    end

    # Returns the amount of statements in the repository, as an integer
    #
    # @return [Integer] the number of statements
    def size
      @resource.size
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
      found = @resource.statements.find(statement_to_dict(statement))
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
    #  @resource.request_http(:get, path(:statements),
    #                     :headers => { 'Accept' => 'text/integer' },
    #                     :expected_status_code => 200).chomp.to_i
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
        @resource.statements.find(dict).each do |statement|
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
        enum_for(:query_pattern, pattern)
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
    def query_execute(query, &block)
      query_options =
        if query.respond_to?(:query_options)
          query.query_options
        else
          {}
        end
      if query.respond_to?(:requires_prolog?) && query.requires_prolog?
        prolog_query(query.to_prolog(self), query_options, &block)
      else
        sparql_query(query_to_sparql(query), query_options, &block)
      end
    end
    protected :query_execute


    #--------------------------------------------------------------------
    # @group AllegroGraph-specific query methods

    # Run a raw SPARQL query.
    #
    # @overload sparql_query(query) {|solution| ... }
    #   @yield solution
    #   @yieldparam [RDF::Query::Solution] solution
    #   @yieldreturn [void]
    #   @return [void]
    #
    # @overload sparql_query(pattern)
    #   @return [Enumerator<RDF::Query::Solution>]
    #
    # @param [String] query The query to run.
    # @param [Hash{Symbol => Object}] query_options
    #   The query options (see build_query).
    # @return [void]
    # @note This function returns a single-use Enumerator!  If you want to
    #   to treat the results as an array, call `to_a` on it, or you will
    #   re-run the query against the server repeatedly.  This curious
    #   decision is made for consistency with RDF.rb.
    #
    # @see #build_query
    def sparql_query(query, query_options={}, &block)
      query_options[:type] = query.split(' ').first.downcase.to_sym unless query.empty?
      raw_query(:sparql, query, query_options, &block)
    end

    # Run a raw Prolog query.
    #
    # @overload prolog_query(query) {|solution| ... }
    #   @yield solution
    #   @yieldparam [RDF::Query::Solution] solution
    #   @yieldreturn [void]
    #   @return [void]
    #
    # @overload prolog_query(pattern)
    #   @return [Enumerator<RDF::Query::Solution>]
    #
    # @param [String] query The query to run.
    # @param [Hash{Symbol => Object}] query_options
    #   The query options (see build_query).
    # @return [void]
    # @note This function returns a single-use Enumerator!  If you want to
    #   to treat the results as an array, call `to_a` on it, or you will
    #   re-run the query against the server repeatedly.  This curious
    #   decision is made for consistency with RDF.rb.
    #
    # @see #build_query
    def prolog_query(query, query_options={}, &block)
      raw_query(:prolog, query, query_options, &block)
    end

    # Run a raw query in the specified language.
    def raw_query(language, query, query_options={}, &block)
      # Build our query parameters.
      params = {
        :query => query,
        :queryLn => language.to_s
      }.merge!(@query_options).merge!(filter_query_options(query_options))

      # Run the query and process the results.
      json = @resource.request_json(:get, path, :parameters => params,
                                :expected_status_code => 200)

      # Parse the result (depends on the type of the query)
      if language == :sparql and query_options[:type] == :construct
        results = json_to_graph(json)
      else
        results = json_to_query_solutions(json)
        results = enum_for(:raw_query, language, query) unless block_given?
      end
      if block_given?
        results.each {|s| yield s }
      else
        results
      end
    end
    protected :raw_query

    # Construct an AllegroGraph-specific query.
    #
    # @param [Hash{Symbol => Object}] query_options
    # @option query_options [true,false,String] :infer
    #   The AllegroGraph inference mode to use.  Defaults to `false`.  The
    #   value `true` is equivalent to `'rdfs++'`.
    # @yield query
    # @yieldparam [Query] The query to build.  Use the Query API to add
    #   patterns and functors.
    # @yieldreturn [void]
    # @return [Query]
    #
    # @see Query
    # @see RDF::Query
    def build_query(query_options={}, &block)
      Query.new(self, query_options, &block)
    end


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
      case @format
      when :json
        json = statements_to_json(statements)
        @resource_writable.request_json(:post, path_writable(:statements),
          :parameters => prepare_filter_insert_options(@insert_options),
          :body => json,
          :expected_status_code => 204)
      when :ntriples
        text = statements_to_text_plain(statements)
        @resource_writable.request_http(:post, path_writable(:statements),
          :parameters => prepare_filter_insert_options(@insert_options),
          :body => text,
          :expected_status_code => 200,
          :headers => { "Content-Type" => "text/plain" })
      else
        raise "Format #{@format} not supported"
      end
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
      @resource_writable.request_json(:post, path_writable('statements/delete'),
                         :body => json, :expected_status_code => 204)
    end
    protected :delete_statements

    # TODO: Override delete to implement fast wildcard deletion without
    # having to first query for the matching records.

    # Clear all statements from the repository.
    #
    # @param [Hash] options
    # @option options [String] :subject Match a specific subject
    # @option options [String] :predicate Match a specific predicate
    # @option options [String] :object Match a specific object
    # @option options [String] :context Match a specific graph name.
    # @return [void]
    def clear(options = {})
      @resource_writable.statements.delete(prepare_filter_insert_options(options))
    end


    #--------------------------------------------------------------------
    # @group Serialization methods

    # Serialize an RDF::Value for transmission to the server.  This
    # is exported for low-level libraries that need to access our
    # serialization and deserialization machinery, which has special-case
    # support for RDF nodes.
    #
    # @param [RDF::Value,RDF::Query::Variable] value
    # @return [String]
    # @see #serialize_prolog
    def serialize(value)
      case value
      when RDF::Query::Variable then value.to_s
      when false then nil
      else RDF::NTriples::Writer.serialize(map_to_server(value))
      end
    end

    # Serialize an RDF::Value for use in a Prolog expression that will
    # be transmitted to the server.
    #
    # @param [RDF::Value,RDF::Query::Variable] value
    # @return [String]
    # @see #serialize
    def serialize_prolog(value)
      case value
      when RDF::AllegroGraph::Query::PrologLiteral then value.to_s
      when RDF::Query::Variable then value.to_s
      else "!#{serialize(value)}"
      end
    end


    protected

    # Build a repository-relative path.
    def path(relative_path=nil)
      if relative_path
        "#{@resource.path}/#{relative_path}"
      else
        @resource.path
      end
    end

    # Build a repository-relative path for the writable mirror
    def path_writable(relative_path=nil)
      if relative_path
        "#{@resource_writable.path}/#{relative_path}"
      else
        @resource_writable.path
      end
    end

    # Deserialize an RDF::Value received from the server, or an array of such
    # values when working with Prolog queries.
    #
    # @param [String,Array] str_or_array
    #   A string, or a possibly-nested array of strings.
    # @return [RDF::Value]
    # @see #serialize
    def unserialize(str_or_array)
      case str_or_array
      when Array then str_or_array.map {|v| unserialize(v) }
      else map_from_server(RDF::NTriples::Reader.unserialize(str_or_array))
      end
    end

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
      }.merge!(@query_options)
    end

    # Convert a list of statements to a text-plain-compatible text.
    def statements_to_text_plain(statements)
      graph = RDF::Repository.new
      statements.each do |s|
        graph << s
      end
      RDF::NTriples::Writer.dump(graph, nil, :encoding => Encoding::ASCII)
    end

    # Convert a query to SPARQL.
    def query_to_sparql(query)
      variables = []
      patterns = []
      query.patterns.each do |p|
        variables.concat(p.variables.values)
        triple = [p.subject, p.predicate, p.object]
        str = triple.map {|v| serialize(v) }.join(" ")
        # TODO: Wrap in graph block for context!
        if p.optional?
          str = "OPTIONAL { #{str} }"
        end
        patterns << "#{str} ."
      end
      "SELECT #{variables.uniq.join(" ")}\nWHERE {\n  #{patterns.join("\n  ")} }"
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

    # Convert a JSON triples list to a RDF::Graph object.
    def json_to_graph(json)
      statements = json.map {|t| RDF::Statement.new(unserialize(t[0]), unserialize(t[1]), unserialize(t[2]))}
      graph = RDF::Graph.new
      graph.insert_statements(statements)
      graph
    end

    # Return true if this a blank RDF node.
    def blank_node?(value)
      !value.nil? && value.anonymous?
    end

    # Ask AllegroGraph to generate a series of blank node IDs.
    def generate_blank_nodes(amount)
      response = @resource.request_http(:post, path(:blankNodes),
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

    # Translate this value to a server-specific representation, taking
    # care to handle blank nodes correctly.
    def map_to_server(value)
      return value unless blank_node?(value)
      unless @blank_nodes_local_to_server.has_key?(value.id)
        new_id = allocate_blank_node
        map_blank_node(value.id, new_id)
      end
      RDF::Node.new(@blank_nodes_local_to_server[value.id])
    end

    # Translate this value to a client-specific representation, taking
    # care to handle blank nodes correctly.
    def map_from_server(value)
      return value unless blank_node?(value)
      if @blank_nodes_server_to_local.has_key?(value.id)
        RDF::Node.new(@blank_nodes_server_to_local[value.id])
      else
        # We didn't generate this node ID, so we want to pass it back to
        # the server unchanged.
        map_blank_node(value.id, value.id)
        value
      end
    end

    # @private
    def filter_query_options(options)
      options||={}
      options.select { |k,v| AUTH_QUERY_OPTIONS.include?(k) }
    end
    protected :filter_query_options

    # @private
    def filter_insert_options(options)
      options||={}
      options.select { |k,v| AUTH_INSERT_OPTIONS.include?(k) && v }
    end
    protected :filter_insert_options

    private

    def prepare_context(context)
      if context.to_s != 'null'
        "\"#{context}\""
      else
        context
      end
    end

    def prepare_filter_insert_options(options)
      options = options.dup
      options[:context] = prepare_context(options[:context]) if options[:context]
      options
    end
  end
end
