require 'spec_helper'

describe RDF::AllegroGraph::Functors::SnaFunctors do
  before :each do
    @real_repository = RDF::AllegroGraph::Repository.new(REPOSITORY_OPTIONS)
    @repository = @real_repository.session
  end

  after :each do
    @repository.close unless @repository.nil? # We might have closed it.
    @real_repository.clear
  end

  describe "#ego_group_member" do
    it "can calculate the ego group of a resource" do
      @repository.insert(
        [EX.me, FOAF.knows, EX.bill],
        [EX.bill, EX.friend, EX.rachel],
        [EX.rachel, FOAF.knows, EX.gary]
      )

      knows = @repository.generator(:object_of => [FOAF.knows, EX.friend])
      solutions = @repository.build_query do |q|
        q.ego_group_member EX.me, 2, knows, :person
      end.run.to_a

      solutions.should include_solution(:person => EX.me)
      solutions.should include_solution(:person => EX.bill)
      solutions.should include_solution(:person => EX.rachel)
      solutions.should_not include_solution(:person => EX.gary)
    end
  end
end
