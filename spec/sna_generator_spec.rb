require 'spec_helper'

describe RDF::AllegroGraph::SnaGenerator do
  it "collects a list of edge types and converts them to URL query paramters" do
    options = {
      :object_of => FOAF.knows,
      :subject_of => [EX.knows1, EX.knows2],
      :undirected => EX.knows3
    }
    generator = RDF::AllegroGraph::SnaGenerator.new(:knows, options)
    generator.name.should == :knows
    generator.to_params.should == {
      :objectOf => FOAF.knows.to_s,
      :subjectOf => [EX.knows1.to_s, EX.knows2.to_s],
      :undirected => EX.knows3.to_s
    }
  end
end
