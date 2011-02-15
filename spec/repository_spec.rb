# This code is based on http://blog.datagraph.org/2010/04/rdf-repository-howto

require 'spec_helper'
require 'rdf/spec/repository'

RSpec::Matchers.define :include_solution do |hash|
  match do |solutions|
    solutions.any? {|s| s.to_hash == hash }
  end
end

describe RDF::AllegroGraph::Repository do
  before :each do
    @repository = RDF::AllegroGraph::Repository.new(REPOSITORY_OPTIONS)
  end

  after :each do
    @repository.clear
  end

  # This pulls in a huge number of specifications from rdf-spec, ensuring
  # that we implement the standard API correctly.
  it_should_behave_like RDF_Repository

  describe "#supports?" do
    it "returns true if passed :context" do
      @repository.supports?(:context).should == true
    end

    it "returns false if passed an unsupported feature" do
      @repository.supports?(:no_such_feature).should == false
    end
  end

  context "with example data" do
    before :each do
      path = File.join(File.dirname(__FILE__), '..', 'etc', 'doap.nt')
      @repository.load(path)
    end

    describe "#delete_statement (protected)" do
      it "deletes a single, valid statement" do
        stmt = RDF::Statement.new(RDF::URI("http://ar.to/#self"),
                                  FOAF.mbox,
                                  RDF::URI("mailto:arto.bendiken@gmail.com"))
        @repository.should have_statement(stmt)
        # This method is protected, but we're required to override it.
        # Unfortuantely, because we also override delete_statements,
        # there's no way for it to get called using public APIs.  So we
        # bypass the 'protected' restriction using 'send'.
        @repository.send(:delete_statement, stmt)
        @repository.should_not have_statement(stmt)
      end
    end

    describe "#query on a Basic Graph Pattern" do
      it "matches all required patterns" do
        query = RDF::Query.new do |q|
          q.pattern [:person, RDF.type, FOAF.Person]
          q.pattern [:person, FOAF.name, :name]
          q.pattern [:person, FOAF.mbox, :email]
        end
        s = @repository.query(query)
        s.should include_solution(:person => "http://ar.to/#self",
                                  :name => "Arto Bendiken",
                                  :email => "mailto:arto.bendiken@gmail.com")
        s.should include_solution(:person => "http://bhuga.net/#ben",
                                  :name => "Ben Lavender",
                                  :email => "mailto:blavender@gmail.com")
        s.should include_solution(:person => "http://kellogg-assoc.com/#me",
                                  :name => "Gregg Kellogg",
                                  :email => "mailto:gregg@kellogg-assoc.com")
      end

      it "match optional patterns when appropriate" do
        query = RDF::Query.new do |q|
          q.pattern [:person, RDF.type, FOAF.Person]
          q.pattern [:person, FOAF.made, :made], :optional => true
        end
        s = @repository.query(query)
        s.should include_solution(:person => "http://ar.to/#self",
                                  :made => "http://rubygems.org/gems/rdf")
        s.should include_solution(:person => "http://bhuga.net/#ben")
        s.should include_solution(:person => "http://kellogg-assoc.com/#me")
      end

      it "runs AllegroGraph-specific queries" do
        query = RDF::AllegroGraph::Query.new do |q|
          q.pattern [:person, RDF.type, FOAF.Person]
          q.pattern [:person, FOAF.made, :made], :optional => true
        end
        s = @repository.query(query)
        s.should include_solution(:person => "http://ar.to/#self",
                                  :made => "http://rubygems.org/gems/rdf")
        s.should include_solution(:person => "http://bhuga.net/#ben")
        s.should include_solution(:person => "http://kellogg-assoc.com/#me")
      end

      # TODO: RDF::Query::Pattern doesn't really support contexts yet,
      # so we can't try to match it.
      #context "with contexts" do
      #  before do
      #    @repository.insert([EX.s1, EX.p, EX.o],
      #                       [EX.s2, EX.p, EX.o, EX.c2])
      #  end
      #
      #  it "matches statements with and without a context" do
      #    query = RDF::Query.new {|q| q.pattern [:s, EX.p, EX.o] }
      #    s = @repository.query(query)
      #    s.should include_solution(:s => EX.s1)
      #    s.should include_solution(:s => EX.s2)
      #  end
      #end
    end

    describe "blank node mapping" do
      it "correctly handle blank nodes that originate in the repository" do
        @repository2 = RDF::AllegroGraph::Repository.new(REPOSITORY_OPTIONS)
        @repository2.each {|stmt| @repository2.should have_statement(stmt) }
      end
    end
  end

  describe "#serialize" do
    it "transforms RDF::Value objects into strings" do
      @repository.serialize(RDF::URI("http://example.com/")).should ==
        "<http://example.com/>"
      @repository.serialize(RDF::Literal.new("string")).should == "\"string\""
    end

    it "maps blank nodes to a server-specific representation" do
      @repository.serialize(RDF::Node.intern('x')).should_not == "_:x"
    end

    it "serializes variables with a leading '?'" do
      @repository.serialize(RDF::Query::Variable.new(:x)).should == "?x"
    end
  end

  describe "#unserialize" do
    it "transforms strings into RDF::Value objects" do
      @repository.unserialize("<http://example.com/>").should ==
        RDF::URI("http://example.com/")
      @repository.unserialize("\"str\"").should == RDF::Literal.new("str")
    end

    it "maps blank node names back to their original values" do
      blank = @repository.serialize(RDF::Node.intern('x'))
      @repository.unserialize(blank).should == RDF::Node.intern('x')
    end
  end
end
