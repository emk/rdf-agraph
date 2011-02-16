# This code is based on http://blog.datagraph.org/2010/04/rdf-repository-howto

require 'spec_helper'

describe RDF::AllegroGraph::Repository do
  before :each do
    @repository = RDF::AllegroGraph::Repository.new(REPOSITORY_OPTIONS)
  end

  after :each do
    @repository.clear
  end

  it_should_behave_like RDF::AllegroGraph::AbstractRepository
end
