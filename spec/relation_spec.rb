require 'spec_helper'

describe RDF::AllegroGraph::Query::Relation do
  subject do
    relation = RDF::AllegroGraph::Query::Relation
    relation.new('ego-group-member', EX.me, 2, FOAF.knows, :person)
  end

  it "has a name" do
    subject.name.should == 'ego-group-member'
  end
end
