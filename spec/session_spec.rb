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

  describe "Social Network Analysis" do
    it "can calculate the ego group of a resource" do
      @repository.insert(
        [EX.me, FOAF.knows, EX.bill],
        [EX.bill, EX.friend, EX.rachel],
        [EX.rachel, FOAF.knows, EX.gary]
      )

      @repository.define_generator(:knows,
                                   :object_of => [FOAF.knows, EX.friend])
      query = RDF::AllegroGraph::Query.new do |q|
        q.ego_group_member EX.me, 2, :knows, :person
      end
      s = @repository.query(query)
      s.should include_solution(:person => EX.me)
      s.should include_solution(:person => EX.bill)
      s.should include_solution(:person => EX.rachel)
      s.should_not include_solution(:person => EX.gary)
    end
  end
end
