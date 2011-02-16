module RDF::AllegroGraph
  class SnaGenerator
    attr_reader :name
    attr_reader :options

    def initialize(name, options)
      @name = name
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
        when Array then { param_name => value.map {|v| v.to_s } }
        else { param_name => value.to_s }
        end
      else
        {}
      end
    end
  end
end
