require 'spec_helper'

describe RDF::AllegroGraph::Query::Relation do
  subject do
    relation = RDF::AllegroGraph::Query::Relation
    relation.new('ego-group-member', EX.me, 2, FOAF.knows, :person)
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
    it "returns a hash table of all variables in the relation" do
      subject.variables[:person].should be_instance_of(RDF::Query::Variable)
    end
  end
end
