# This code is based on http://blog.datagraph.org/2010/04/rdf-repository-howto

$: << File.join(File.dirname(__FILE__), "../lib")

require 'rubygems'
gem 'bundler'
require 'bundler'
Bundler.require

require 'rdf/spec/repository'
require 'rdf'
require 'rdf/agraph'

describe RDF::AllegroGraph::Repository do
  before :each do
    options = {
      :username => 'test',
      :password => 'test',
      :repository => 'rdf_agraph_test'
    }
    @repository = RDF::AllegroGraph::Repository.new(options)
  end

  after :each do
    @repository.clear
  end

  # @see lib/rdf/spec/repository.rb
  it_should_behave_like RDF_Repository
end
