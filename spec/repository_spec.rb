require 'spec_helper'

describe RDF::AllegroGraph::Repository do
  before :each do
    @repository = RDF::AllegroGraph::Repository.new(REPOSITORY_OPTIONS)
  end

  after :each do
    @repository.clear
  end

  it_should_behave_like RDF::AllegroGraph::AbstractRepository

  describe ".new" do
    it "allows the user to pass a repository URL" do
      url = "#{REPOSITORY_OPTIONS[:url]}/repositories/#{REPOSITORY_OPTIONS[:id]}"
      @repository2 = RDF::AllegroGraph::Repository.new(url)
      statement = RDF::Statement.from([EX.me, RDF.type, FOAF.Person])
      @repository2.insert(statement)
      @repository2.should have_statement(statement)
    end

    it "allows the user to pass a repository URL belonging to a catalog" do
      @repository2 = RDF::AllegroGraph::Repository.new(CATALOG_REPOSITORY_OPTIONS)
      statement = RDF::Statement.from([EX.me, RDF.type, FOAF.Person])
      @repository2.insert(statement)
      @repository2.should have_statement(statement)
      @repository2.clear
    end
  end

  describe "repository creation and deletion" do
    it "is performed using #new with :create and delete!" do
      server = REPOSITORY_OPTIONS[:server]
      url = "#{REPOSITORY_OPTIONS[:url]}/repositories/rdf_agraph_test_2"
      @repository2 = RDF::AllegroGraph::Repository.new(url, :create => true)
      server.should have_repository('rdf_agraph_test_2')
      @repository2.delete!
      server.should_not have_repository('rdf_agraph_test_2')
    end
  end

  describe "#session" do
    context "without a block" do
      it "creates and returns a session" do
        session = @repository.session
        session.should be_kind_of(RDF::AllegroGraph::Session)
        session.close
      end
    end

    context "with a block" do
      before do
        @statement = RDF::Statement.from([EX.me, RDF.type, FOAF.Person])
      end

      it "commits and closes the session if no error occurs" do
        saved_session = nil
        @repository.session do |session|
          session.should be_kind_of(RDF::AllegroGraph::Session)
          saved_session = session
          session.insert(@statement)
          "Result"
        end.should == "Result"
        @repository.should have_statement(@statement)
        lambda { saved_session.close }.should raise_error
      end

      it "rolls back and closes the session if an error occurs" do
        lambda do
          @repository.session do |session|
            session.should be_kind_of(RDF::AllegroGraph::Session)
            saved_session = session
            session.insert(@statement)
            raise "Forced failure"
          end
        end.should raise_error("Forced failure")
        @repository.should_not have_statement(@statement)
        lambda { saved_session.close }.should raise_error
      end
    end
  end
end
