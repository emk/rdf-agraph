require 'spec_helper'
require 'rdf/spec/query'

describe RDF::AllegroGraph::Query do

  before :each do
    @repository = RDF::AllegroGraph::Repository.new(REPOSITORY_OPTIONS)
    @new = RDF::AllegroGraph::Query.method(:new)
  end

  after :each do
    @repository.clear
  end

  it_should_behave_like RDF_Query

  describe "#to_prolog" do
    it "converts the query to AllegroGraph's Lisp-like Prolog syntax" do
      query = RDF::AllegroGraph::Query.new do |q|
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
  end
end
