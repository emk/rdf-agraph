require 'spec_helper'

shared_examples_for "a path functor" do
  it "returns one or more paths between the specified nodes" do
    slns = @repository.build_query do |q|
      q.send(@functor, EX.me, EX.rachel, @knows, :path)
    end.run.to_a
    slns.length.should >= 1
    slns.each do |s|
      s.path.first.should == EX.me
      s.path.last.should == EX.rachel
    end
  end

  it "honors :max_length" do
    slns = @repository.build_query do |q|
      q.send(@functor, EX.me, EX.rachel, @knows, :path, :max_depth => 1)
    end.run.to_a
    slns.should be_empty
  end
end

describe RDF::AllegroGraph::Functors::SnaFunctors do
  before :each do
    @real_repository = RDF::AllegroGraph::Repository.new(REPOSITORY_OPTIONS)
    @repository = @real_repository.session
  end

  after :each do
    @repository.close unless @repository.nil? # We might have closed it.
    @real_repository.clear
  end

  context "with a graph containing multiple paths" do
    before do
      @repository.insert(
        # Path 1: me -> bill -> rachel
        [EX.me, FOAF.knows, EX.bill],
        [EX.bill, FOAF.knows, EX.rachel],
        # Path 2: me -> sally -> rachel
        [EX.me, FOAF.knows, EX.sally],
        [EX.sally, FOAF.knows, EX.rachel],
        # Path 3: me -> sam -> ben -> rachel
        [EX.me, FOAF.knows, EX.sam],
        [EX.sam, FOAF.knows, EX.ben],
        [EX.ben, FOAF.knows, EX.rachel]
      )
      @knows = @repository.generator(:object_of => FOAF.knows)
    end

    describe "#breadth_first_search_paths" do
      before { @functor = "breadth_first_search_paths" }
      it_should_behave_like "a path functor"
        
      it "returns the shortest paths between the specified nodes" do
        slns = @repository.build_query do |q|
          q.breadth_first_search_paths(EX.me, EX.rachel, @knows, :path)
        end.run.to_a
        slns.should include_solution(:path => [EX.me, EX.bill, EX.rachel])
        slns.should include_solution(:path => [EX.me, EX.sally, EX.rachel])
        slns.should_not include_solution(:path => [EX.me, EX.sam, EX.ben,
                                                   EX.rachel])
      end
    end

    describe "#depth_first_search_paths" do
      before { @functor = "depth_first_search_paths" }
      it_should_behave_like "a path functor"
    end

    describe "#bidirectional_search_paths" do
      before { @functor = "depth_first_search_paths" }
      it_should_behave_like "a path functor"
    end

    describe "#neighbor_count" do
      it "counts the neighboring nodes" do
        solutions = @repository.build_query do |q|
          q.neighbor_count(EX.me, @knows, :n)
        end.run.to_a
        solutions.length.should == 1
        solutions.first.n.should == 3
      end
    end

    describe "#neighbors" do
      it "returns the neighboring nodes" do
        solutions = @repository.build_query do |q|
          q.neighbors(EX.me, @knows, :neighbor)
        end.run.to_a
        solutions.should include_solution(:neighbor =>  EX.bill)
        solutions.should include_solution(:neighbor =>  EX.sally)
        solutions.should include_solution(:neighbor =>  EX.sam)
      end
    end
  end

  context "with a simple FOAF graph" do
    before do
      @repository.insert(
        [EX.me, FOAF.knows, EX.bill],
        [EX.bill, EX.friend, EX.rachel],
        [EX.rachel, FOAF.knows, EX.gary]
      )
      @knows = @repository.generator(:object_of => [FOAF.knows, EX.friend])
    end

    describe "#ego_group" do
      it "returns the entire ego group as a list" do
        solutions = @repository.build_query do |q|
          q.ego_group EX.me, 2, @knows, :group
        end.run.to_a

        solutions.length.should == 1
        group = solutions[0].group        
        group.should include(EX.me, EX.bill, EX.rachel)
        group.should_not include(EX.gary)
      end
    end

    describe "#ego_group_member" do
      it "can calculate the ego group of a resource" do
        solutions = @repository.build_query do |q|
          q.ego_group_member EX.me, 2, @knows, :person
        end.run.to_a

        solutions.should include_solution(:person => EX.me)
        solutions.should include_solution(:person => EX.bill)
        solutions.should include_solution(:person => EX.rachel)
        solutions.should_not include_solution(:person => EX.gary)
      end
    end
  end
end
