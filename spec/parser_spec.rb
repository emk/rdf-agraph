require 'spec_helper'

module RDF::AllegroGraph

  describe Parser do

    describe ".parse_uri" do
      before do
        Catalog.stub(:new)
        Server.stub(:new)
      end

      it 'should parse a root-catalog repository' do
        hash = Parser::parse_uri("#{REPOSITORY_OPTIONS[:url]}/repositories/repo_name")
        hash.should have_key(:server)
        hash.should_not have_key(:catalog)
        hash[:id].should == 'repo_name'
      end

      it 'should parse a user-catalog repository' do
        hash = Parser::parse_uri("#{REPOSITORY_OPTIONS[:url]}/catalogs/cat_name/repositories/repo_name")
        hash.should have_key(:catalog)
        hash.should_not have_key(:server)
        hash[:id].should == 'repo_name'
      end

    end

  end

end