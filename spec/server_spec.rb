require 'spec_helper'

describe RDF::AllegroGraph::Server do
  # These tests are copied from
  # https://github.com/bendiken/rdf-sesame/blob/master/spec/server_spec.rb
  # and modified to remove 'url' and 'connection'.
  describe "RDF::Sesame compatibility" do
    before :each do
      @url    = REPOSITORY_OPTIONS[:url]
      @server = RDF::AllegroGraph::Server.new(@url)
    end

    it "returns the protocol version" do
      @server.should respond_to(:protocol, :protocol_version)
      @server.protocol.should be_a_kind_of(Numeric)
      @server.protocol.should >= 4
    end

    it "returns available repositories" do
      @server.should respond_to(:repositories)
      @server.repositories.should be_a_kind_of(Enumerable)
      @server.repositories.should be_instance_of(Hash)
      @server.repositories.each do |identifier, repository|
        identifier.should be_instance_of(String)
        repository.should be_instance_of(RDF::AllegroGraph::Repository)
      end
    end

    it "indicates whether a repository exists" do
      @server.should respond_to(:has_repository?)
      @server.has_repository?(REPOSITORY_OPTIONS[:id]).should be_true
      @server.has_repository?(:foobar).should be_false
    end

    it "returns existing repositories" do
      @server.should respond_to(:repository, :[])
      repository = @server.repository(REPOSITORY_OPTIONS[:id])
      repository.should_not be_nil
      repository.should be_instance_of(RDF::AllegroGraph::Repository)
    end

    it "does not return nonexistent repositories" do
      lambda { @server.repository(:foobar) }.should_not raise_error
      repository = @server.repository(:foobar)
      repository.should be_nil
    end

    it "supports enumerating repositories" do
      @server.should respond_to(:each_repository, :each)
      # @server.each_repository.should be_an_enumerator
      @server.each_repository do |repository|
        repository.should be_instance_of(RDF::AllegroGraph::Repository)
      end
    end

    it "returns available catalogs" do
      @server.should respond_to(:catalogs)
      @server.catalogs.should be_a_kind_of(Enumerable)
      @server.catalogs.should be_instance_of(Hash)
      @server.catalogs.each do |identifier, catalog|
        identifier.should be_instance_of(String)
        catalog.should be_instance_of(RDF::AllegroGraph::Catalog)
      end
    end

    it "indicates whether a catalog exists" do
      @server.should respond_to(:has_catalog?)
      @server.has_catalog?(CATALOG_REPOSITORY_OPTIONS[:catalog_id]).should be_true
      @server.has_catalog?(:foobar).should be_false
    end

    it "returns existing catalog" do
      @server.should respond_to(:catalog)
      catalog = @server.catalog(CATALOG_REPOSITORY_OPTIONS[:catalog_id])
      catalog.should_not be_nil
      catalog.should be_instance_of(RDF::AllegroGraph::Catalog)
    end

    it "does not return nonexistent catalogs" do
      lambda { @server.catalog(:foobar) }.should_not raise_error
      catalog = @server.catalog(:foobar)
      catalog.should be_nil
    end

    it "supports enumerating catalogs" do
      @server.should respond_to(:each_catalog, :each)
      # @server.each_repository.should be_an_enumerator
      @server.each_catalog do |catalog|
        catalog.should be_instance_of(RDF::AllegroGraph::Catalog)
      end
    end

    it "returns the initfile" do
      @server.should respond_to(:initfile)
      content = @server.initfile || ""
      content.should be_instance_of(String)
    end

  end
end
