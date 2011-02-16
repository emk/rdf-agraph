class RDF::AllegroGraph::Query

  # A relational expression in a Prolog query (other than an ordinary
  # pattern).
  #
  # @see RDF::Query::Pattern
  class Relation
    # The name of this relation.
    attr_reader :name

    # The arguments passed to this relation.
    attr_reader :arguments

    # Construct a new relation.
    #
    # @param [String] name
    # @param [Array<Symbol,RDF::Value,value>] arguments
    #   The arguments to the relation, which may be either variables,
    #   RDF::Value objects, or Ruby values that we can convert to literals.
    # @return [Relation]
    def initialize(name, *arguments)
      @name = name
      @arguments = arguments.map do |arg|
        case arg
        when Symbol then RDF::Query::Variable.new(arg)
        when RDF::Value then arg
        else RDF::Literal.new(arg)
        end
      end
    end

    # Return a hash table of all variables used in this relation.  This
    # is intended to be duck-type compatible with the same method in
    # RDF::Query::Pattern.
    #
    # @return [Hash<Symbol,RDF::Query::Variable>]
    # @see RDF::Query::Pattern#variables
    def variables
      result = {}
      @arguments.each do |arg|
        result.merge!(arg.variables) if arg.is_a?(RDF::Query::Variable)
      end
      result
    end

    # Convert this relation to a Prolog Lisp expression.
    #
    # @param [RDF::AllegroGraph::Repository] repository
    # @return [String]
    # @private
    def to_prolog(repository)
      args = arguments.map {|a| repository.serialize_prolog(a) }
      "(#{name} #{args.join(" ")})"
    end
  end
end
