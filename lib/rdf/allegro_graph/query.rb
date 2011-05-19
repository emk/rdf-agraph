module RDF::AllegroGraph

  # A query with AllegroGraph-specific extensions.
  #
  # Note that many of of the more exotic features of this class can only be
  # used when running Prolog queries against a Session object.  This
  # requires both elevated AllegroGraph privileges and dedicated back-end
  # session resources on the server, so plan accordingly.
  #
  # The Functors module contains a wide variety of functors which may be
  # used when building a Prolog query.
  #
  # @see AbstractRepository#build_query
  # @see Functors
  class Query < RDF::Query
    autoload :PrologLiteral, 'rdf/allegro_graph/query/prolog_literal'
    autoload :FunctorExpression, 'rdf/allegro_graph/query/functor_expression'

    # Include our APIs.
    include Functors::SnaFunctors

    # Our query options.
    #
    # @see AbstractRepository#build_query
    attr_reader :query_options

    # Create a new query.
    # @private
    def initialize(repository, query_options={}, &block)
      @repository = repository
      @query_options = query_options
      super(&block)
    end

    # Run this query against the associated repository.  This method exists
    # solely to make the following API pleasant to use:
    #
    #     repo.build_query do |q|
    #       q.pattern [:s, :p, :o]
    #     end.run do |solution|
    #       puts solution
    #     end
    #
    # Note that this function returns an Enumerator, not an array, because
    # RDF.rb is committed to streaming results gradually.  If you want to
    # treat the result as an array, call 'to_a' explicitly:
    #
    #     solutions = repo.build_query do |q|
    #       q.pattern [:s, :p, :o]
    #     end.run.to_a
    #
    # If you forget to do this, you will run a new query each time you
    # attempt to iterate over the solutions!
    #
    # @overload run
    #   @return [Enumerator<RDF::Query::Solution>]
    #
    # @overload run
    #   @yield solution
    #   @yieldparam [RDF::Query::Solution]
    #   @yieldreturn [void]
    #   @return [void]
    #
    # @see Repository#query
    # @note This function returns a single-use Enumerator!  If you want to
    #   to treat the results as an array, call `to_a` on it, or you will
    #   re-run the query against the server repeatedly.  This curious
    #   decision is made for consistency with RDF.rb.
    def run(&block)
      @repository.query(self, &block)
    end

    # Add a functor expression to this query.  Functors can only be used
    # in Prolog queries.
    #
    # @param [String] name
    # @param [Array<Symbol,RDF::Value,value>] arguments
    #   The arguments to the functor, which may be either variables,
    #   RDF::Value objects, or Ruby values that we can convert to literals.
    # @return [void]
    def functor(name, *arguments)
      # TODO: Don't abuse duck-typing quite so much.
      patterns <<
        RDF::AllegroGraph::Query::FunctorExpression.new(name, *arguments)
    end

    # Does this query contain Prolog-specific functors that we can't
    # represent as SPARQL?
    #
    # @return [Boolean]
    def requires_prolog?
      !patterns.all? {|p| p.kind_of?(RDF::Query::Pattern) }
    end

    # Convert this query to AllegoGraph Prolog notation.
    #
    # @param [RDF::AllegroGraph::Repository] repository
    # @return [String]
    # @private
    def to_prolog(repository)
      variables = []
      functors = []
      patterns.each do |p|
        # Extract any new variables we see in the query.
        p.variables.each {|_,v| variables << v unless variables.include?(v) }
        functors << convert_to_functor(p).to_prolog(repository)
      end
      "(select (#{variables.join(" ")})\n  #{functors.join("\n  ")})"
    end

    protected

    # Convert patterns to functors (and leave functors unchanged).
    #
    # @param [RDF::Query::Pattern,FunctorExpression] pattern_or_functor
    # @return [FunctorExpression]
    # @private
    def convert_to_functor(pattern_or_functor)
      case pattern_or_functor
      when FunctorExpression then pattern_or_functor
      else
      p = pattern_or_functor
        if p.optional? || p.context
          raise ArgumentError.new("Can't translate #{p} to Prolog functor")
        end
        FunctorExpression.new('q-', p.subject, p.predicate, p.object)
      end
    end
  end
end
