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
      relations = []
      patterns.each do |p|
        # Extract any new variables we see in the query.
        p.variables.each {|_,v| variables << v unless variables.include?(v) }
        relations << convert_to_relation(p).to_prolog(repository)
      end
      "(select (#{variables.join(" ")})\n  #{relations.join("\n  ")})"
    end

    protected

    # Convert patterns to relations (and leave relations unchanged).
    #
    # @param [RDF::Query::Pattern,Relation] pattern_or_relation
    # @return [Relation]
    # @private
    def convert_to_relation(pattern_or_relation)
      case pattern_or_relation
      when Relation then pattern_or_relation
      else
      p = pattern_or_relation
        if p.optional? || p.context
          raise ArgumentError.new("Can't translate #{p} to Prolog relation")
        end
        Relation.new('q-', p.subject, p.predicate, p.object)
      end
    end
  end
end
