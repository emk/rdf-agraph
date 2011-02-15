# This code is based on http://blog.datagraph.org/2010/04/rdf-repository-howto

require 'spec_helper'
require 'rdf/spec/repository'

RSpec::Matchers.define :include_solution do |hash|
  match do |solutions|
    solutions.any? {|s| s.to_hash == hash }
  end
end

describe RDF::AllegroGraph::Repository do
  FOAF = RDF::FOAF

  before :each do
    @repository_options = {
      :username => 'test',
      :password => 'test',
      :repository => 'rdf_agraph_test'
    }
    @repository = RDF::AllegroGraph::Repository.new(@repository_options)
  end

  after :each do
    @repository.clear
  end

  # This pulls in a huge number of specifications from rdf-spec, ensuring
  # that we implement the standard API correctly.
  it_should_behave_like RDF_Repository

  describe ".supports?" do
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
    end

    describe "blank node mapping" do
      it "correctly handle blank nodes that originate in the repository" do
        @repository2 = RDF::AllegroGraph::Repository.new(@repository_options)
        @repository2.each {|stmt| @repository2.should have_statement(stmt) }
      end
    end
  end
end
