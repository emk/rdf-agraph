module RDF::AllegroGraph

  # A query with AllegroGraph-specific extensions.
  class Query < RDF::Query
    # Convert this query to AllegoGraph Prolog notation.
    #
    # @param [RDF::AllegroGraph::Repository] repository
    # @return [String]
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
        str = triple.map do |value|
          case value
          when RDF::Query::Variable then value.to_s
          else "!#{repository.serialize(value)}"
          end
        end.join(" ")
        pattern_strs << "(q- #{str})"
      end
      "(select (#{variables.join(" ")})\n  #{pattern_strs.join("\n  ")})"
    end
  end
end
