require 'spec_helper'

describe RDF::AllegroGraph::Session do
  before :each do
    @real_repository = RDF::AllegroGraph::Repository.new(REPOSITORY_OPTIONS)
    @repository = @real_repository.session
  end

  after :each do
    @repository.close unless @repository.nil? # We might have closed it.
    @real_repository.clear
  end

  it_should_behave_like RDF::AllegroGraph::AbstractRepository

  describe "#close" do
    it "destroys the underlying session" do
      @repository.close
      lambda { @repository.close }.should raise_error
      @repository = nil
    end

    it "does not commit outstanding transactions" do
      @statement = RDF::Statement.from([EX.me, RDF.type, FOAF.Person])
      @repository.insert(@statement)
      @repository.close
      @repository = nil
      @real_repository.should_not have_statement(@statement)      
    end
  end

  describe "transaction" do
    before do
      @statement = RDF::Statement.from([EX.me, RDF.type, FOAF.Person])
      @repository.insert(@statement)
    end

    it "does not show changes to other sessions before commit is called" do
      @real_repository.should_not have_statement(@statement)
    end

    it "shows changes to other sessions after commit is called" do
      @repository.commit
      @real_repository.should have_statement(@statement)
    end

    it "discards changes when rollback is called" do
      @repository.rollback
      @real_repository.should_not have_statement(@statement)
      @repository.should_not have_statement(@statement)
    end
  end

  describe "Social Network Analysis" do
    it "can calculate the ego group of a resource" do
      @repository.insert(
        [EX.me, FOAF.knows, EX.bill],
        [EX.bill, EX.friend, EX.rachel],
        [EX.rachel, FOAF.knows, EX.gary]
      )

      knows = @repository.generator(:object_of => [FOAF.knows, EX.friend])
      query = @repository.build_query do |q|
        q.ego_group_member EX.me, 2, knows, :person
      end
      s = @repository.query(query)
      s.should include_solution(:person => EX.me)
      s.should include_solution(:person => EX.bill)
      s.should include_solution(:person => EX.rachel)
      s.should_not include_solution(:person => EX.gary)
    end
  end
end
