class RDF::AllegroGraph::Query

  # A relational expression in a Prolog query (other than an ordinary
  # pattern).
  #
  # @see RDF::Query::Pattern
  class Relation
    # The name of this relation.
    attr_reader :name

    # Construct a new relation.
    #
    # @param [String] name
    # @param [Array<RDF::Query::Variable,RDF::Value,value>] arguments
    #   The arguments to the relation, which may be either variables,
    #   RDF::Value objects, or Ruby values that we can convert to literals.
    # @return [Relation]
    def initialize(name, *arguments)
      @name = name
    end
  end
end
