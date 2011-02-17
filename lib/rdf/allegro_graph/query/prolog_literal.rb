class RDF::AllegroGraph::Query
  # A literal value which can be passed as an argument to a Prolog relation.
  #
  # @see @Relation
  class PrologLiteral
    # Constract a new Prolog literal.
    #
    # @param [Object] value A Ruby value.
    def initialize(value)
      @value = value
    end

    # Serialize this literal as a string.  We need to be careful about
    # security here: Our callers might try to pass in untrustworthy values
    # without thinking through the consequences, and we want to limit the
    # damage.  We assume that all symbols are trustworthy.
    #
    # @return [String]
    def to_s
      case @value
      when Symbol, Numeric
        @value.to_s
      else
        err = "Don't know how to serialize #{@value.inspect} securely"
        raise ArgumentError.new(err)
      end
    end
  end
end
