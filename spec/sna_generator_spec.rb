require 'spec_helper'

describe RDF::AllegroGraph::SnaGenerator do
  it "collects a list of edge types and converts them to URL query paramters" do
    @repo = RDF::AllegroGraph::Repository.new(REPOSITORY_OPTIONS)
    options = {
      :object_of => FOAF.knows,
      :subject_of => [EX.knows1, EX.knows2],
      :undirected => EX.knows3
    }
    generator = RDF::AllegroGraph::SnaGenerator.new(@repo, :knows, options)
    generator.name.should == :knows
    generator.to_params.should == {
      :objectOf => @repo.serialize(FOAF.knows),
      :subjectOf => [@repo.serialize(EX.knows1),
                     @repo.serialize(EX.knows2)],
      :undirected => @repo.serialize(EX.knows3)
    }
  end
end
