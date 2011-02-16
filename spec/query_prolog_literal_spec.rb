require 'spec_helper'

describe RDF::AllegroGraph::Query::PrologLiteral do
  it "stores symbols" do
    RDF::AllegroGraph::Query::PrologLiteral.new(:knows).to_s.should == 'knows'
  end

  it "stores integers" do
    RDF::AllegroGraph::Query::PrologLiteral.new(2).to_s.should == "2"
  end
end
