require 'spec_helper'

describe RDF::AllegroGraph::Session do
  before :each do
    @real_repository = RDF::AllegroGraph::Repository.new(REPOSITORY_OPTIONS)
    @repository = @real_repository.session
  end

  after :each do
    @repository.clear
  end

  it_should_behave_like RDF::AllegroGraph::AbstractRepository
end
