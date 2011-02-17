module RDF::AllegroGraph
  # Internal helper class for defining SNA generators.
  #
  # @private
  class SnaGenerator 
    attr_reader :options

    def initialize(repository, options)
      @repository = repository
      @options = options
    end

    def to_params
      params = {}
      params.merge!(option_to_hash(:objectOf, :object_of))
      params.merge!(option_to_hash(:subjectOf, :subject_of))
      params.merge!(option_to_hash(:undirected, :undirected))
      params
    end

    protected

    def option_to_hash(param_name, option_name)
      if @options.has_key?(option_name)
        value = @options[option_name]
        case value
        when Array
          { param_name => value.map {|v| @repository.serialize(v) } }
        else
          { param_name => @repository.serialize(value) }
        end
      else
        {}
      end
    end
  end
end
