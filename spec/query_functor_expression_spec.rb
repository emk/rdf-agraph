require 'spec_helper'

describe RDF::AllegroGraph::Query::FunctorExpression do
  subject do
    functor = RDF::AllegroGraph::Query::FunctorExpression
    functor.new('ego-group-member', EX.me, 2, FOAF.knows, :person)
  end

  it "has a name" do
    subject.name.should == 'ego-group-member'
  end

  it "has a list of arguments" do
    subject.should have(4).arguments
    subject.arguments[0].should == EX.me
    subject.arguments[1].should be_kind_of(RDF::Literal)
    subject.arguments[1].should == RDF::Literal.new(2)
    subject.arguments[2].should == FOAF.knows
    subject.arguments[3].should be_instance_of(RDF::Query::Variable)
  end

  describe "#variables" do
    it "returns a hash table of all variables in the functor" do
      subject.variables[:person].should be_instance_of(RDF::Query::Variable)
    end
  end

  describe "#to_prolog" do
    before do
      @repository = RDF::AllegroGraph::Repository.new(REPOSITORY_OPTIONS)
    end

    it "serializes a functor as a Prolog query term" do
      subject.to_prolog(@repository).should == <<EOD.chomp
(ego-group-member !<http://example.com/me> !"2"^^<http://www.w3.org/2001/XMLSchema#integer> !<http://xmlns.com/foaf/0.1/knows> ?person)
EOD
    end
  end
end
