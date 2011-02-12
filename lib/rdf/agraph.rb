# This code is based on http://blog.datagraph.org/2010/04/rdf-repository-howto

module RDF
  module AllegroGraph
    class Repository < RDF::Repository
      def initialize(options)
        repository = options[:repository]
        server_options = options.dup
        server_options.delete(:repository)
        @server = ::AllegroGraph::Server.new(server_options)
        @repo = ::AllegroGraph::Repository.new(@server, repository)
        @repo.create_if_missing!        
      end

      def each
        if block_given?
          @repo.statements.find.each do |statement|
            s,p,o,c = statement.map {|v| unserialize(v) }
            if c.nil?
              yield RDF::Statement.new(s,p,o)
            else
              yield RDF::Statement.new(s,p,o,c)
            end
          end
        else
          ::Enumerable::Enumerator.new(self, :each)
        end
      end

      def insert_statement(statement)
        @repo.statements.create(serialize(statement.subject),
                                serialize(statement.predicate),
                                serialize(statement.object),
                                serialize(statement.context))
      end

      def delete_statement(statement)
        @repo.statements.delete(:subject => serialize(statement.subject),
                                :predicate => serialize(statement.predicate),
                                :object => serialize(statement.object),
                                :context => serialize(statement.context))
      end

      def clear
        @repo.statements.delete
      end

      protected

      def serialize(value)
        RDF::NTriples::Writer.serialize(value)
      end

      def unserialize(value)
        RDF::NTriples::Reader.unserialize(value)
      end
    end
  end
end
