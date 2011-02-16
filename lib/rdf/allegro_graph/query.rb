module RDF::AllegroGraph

  # A query with AllegroGraph-specific extensions.
  class Query < RDF::Query
    autoload :Relation, 'rdf/allegro_graph/query/relation'

    # Add a relation to this query.  Relations can only be used in Prolog
    # queries.
    #
    # @param [String] name
    # @param [Array<Symbol,RDF::Value,value>] arguments
    #   The arguments to the relation, which may be either variables,
    #   RDF::Value objects, or Ruby values that we can convert to literals.
    # @return [void]
    def relation(name, *arguments)
      # TODO: Don't abuse duck-typing quite so much.
      patterns << RDF::AllegroGraph::Query::Relation.new(name, *arguments)
    end

    # Convert this query to AllegoGraph Prolog notation.
    #
    # @param [RDF::AllegroGraph::Repository] repository
    # @return [String]
    # @private
    def to_prolog(repository)
      variables = []
      pattern_strs = []
      patterns.each do |p|
        # We don't translate these queries to Prolog yet.
        if p.optional? || p.context
          raise ArgumentError.new("Don't know how to handle #{p}")
        end

        # Extract any new variables we see in the query.
        p.variables.each do |v|
          variables << v[1] unless variables.include?(v[1])
        end

        triple = [p.subject, p.predicate, p.object]
        str = triple.map {|v| repository.serialize_prolog(v) }.join(" ")
        pattern_strs << "(q- #{str})"
      end
      "(select (#{variables.join(" ")})\n  #{pattern_strs.join("\n  ")})"
    end
  end
end
