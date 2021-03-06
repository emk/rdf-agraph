require 'spec_helper'
require 'rdf/spec/queryable'

describe RDF::AllegroGraph::Query do

  before :each do
    @repository = RDF::AllegroGraph::Repository.new(REPOSITORY_OPTIONS)
    @new = RDF::AllegroGraph::Query.method(:new)
    @queryable = @repository
  end

  after :each do
    @repository.clear
  end

  include RDF_Queryable

  describe "#run" do

    context "in any case" do
      before do
        @repository.clear # because of include RDF_Queryable
        @repository.insert(
          [EX.me, RDF.type, FOAF.Person],
          [EX.john, RDF.type, FOAF.Person])
        @query = RDF::AllegroGraph::Query.new(@repository) do |q|
          q.pattern [:person, RDF.type, FOAF.Person]
        end
      end

      it "runs the query against the repository" do
        @query.run.to_a.should include_solution(:person => EX.me)
      end

      it "accepts a block argument" do
        solutions = []
        @query.run {|s| solutions << s }
        solutions.should include_solution(:person => EX.me)
      end

      it "should not limit the number of results by default" do
        sln = @query.run.to_a.should have(2).items
      end

      it "should limit the number of results when passed :limit => n" do
        @repository.build_query(:limit => 1) do |q|
          q << [:person, RDF.type, FOAF.Person]
        end.run.to_a.should have(1).items
      end
    end

    context "with an RDFS/OWL ontology" do
      Concepts = RDF::Vocabulary.new("http://www.example.com/Concepts#")

      before do
        @repository.insert(
          [Concepts.Celine, RDF.type, Concepts.Woman],
          [Concepts.Woman, RDF.type, RDF::OWL.Class],
          [Concepts.Person, RDF.type, RDF::OWL.Class],
          [Concepts.Woman, RDF::RDFS.subClassOf, Concepts.Person])
      end

      it "does not run inference by default" do
        sln = @repository.build_query do |q|
          q << [Concepts.Celine, RDF.type, :klass]
        end.run.to_a
        sln.should include_solution(:klass => Concepts.Woman)
        sln.should_not include_solution(:klass => Concepts.Person)
      end

      it "does run inference when passed :infer => true" do
        sln = @repository.build_query(:infer => true) do |q|
          q << [Concepts.Celine, RDF.type, :klass]
        end.run.to_a
        sln.should include_solution(:klass => Concepts.Woman)
        sln.should include_solution(:klass => Concepts.Person)
      end

      it "does run inference when passed :infer => 'rdfs++'" do
        sln = @repository.build_query(:infer => 'rdfs++') do |q|
          q << [Concepts.Celine, RDF.type, :klass]
        end.run.to_a
        sln.should include_solution(:klass => Concepts.Woman)
        sln.should include_solution(:klass => Concepts.Person)
      end
    end
  end

  describe "#functor" do
    it "adds a functor expression to the list of patterns" do
      query = RDF::AllegroGraph::Query.new(@repository) do |q|
        q.functor 'ego-group-member', EX.me, 2, FOAF.knows, :person
      end
      query.patterns.length.should == 1
      query.patterns[0].
        should be_kind_of(RDF::AllegroGraph::Query::FunctorExpression)
    end
  end

  describe "#.requires_prolog?" do
    it "returns false if the query contains no functors" do
      RDF::AllegroGraph::Query.new(@repository) do |q|
        q.pattern [:person, RDF.type, FOAF.Person]
        q.pattern [:person, FOAF.mbox, :email]
      end.requires_prolog?.should == false
    end

    it "returns true if the query contains functors" do
      RDF::AllegroGraph::Query.new(@repository) do |q|
        q.functor 'ego-group-member', EX.me, 2, FOAF.knows, :person
      end.requires_prolog?.should == true
    end
  end

  describe "#to_prolog" do
    it "converts the query to AllegroGraph's Lisp-like Prolog syntax" do
      query = RDF::AllegroGraph::Query.new(@repository) do |q|
        q.pattern [:person, RDF.type, FOAF.Person]
        q.pattern [:person, FOAF.name, :name]
        q.pattern [:person, FOAF.mbox, "mailto:jsmith@example.com"]
      end
      query.to_prolog(@repository).should == <<EOD.chomp
(select (?person ?name)
  (q- ?person !<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> !<http://xmlns.com/foaf/0.1/Person>)
  (q- ?person !<http://xmlns.com/foaf/0.1/name> ?name)
  (q- ?person !<http://xmlns.com/foaf/0.1/mbox> !"mailto:jsmith@example.com"))
EOD
    end

    it "converts functors to function calls" do
      query = RDF::AllegroGraph::Query.new(@repository) do |q|
        q.functor 'ego-group-member', EX.me, 2, FOAF.knows, :person
      end
      query.to_prolog(@repository).should == <<EOD.chomp
(select (?person)
  (ego-group-member !<http://example.com/me> !"2"^^<http://www.w3.org/2001/XMLSchema#integer> !<http://xmlns.com/foaf/0.1/knows> ?person))
EOD
    end
  end
end
