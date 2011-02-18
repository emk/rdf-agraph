# rdf-agraph: Ruby AllegroGraph adapter for RDF.rb

[RDF.rb][rdfrb] is an excellent Ruby library for working with RDF.
[AllegroGraph][allegrograph] is a commercial RDF data store written in
Lisp.  AllegroGraph supports advanced graph queries and social network
analysis.

This gem provides an optimized implementaton of RDF.rb's `Repository`
interface.  It supports bulk loads, bulk deletes, optimized statement
queries and even optimized Basic Graph Pattern queries.  At the time of
writing, I'm not aware of any other RDF.rb `Repository` that optimizes all
of the above.

Note, however, that this gem exposes only a small fraction of
AllegroGraph's features.  To help add more features, see
[Contributing](#Contributing_to_rdf-agraph) below.

* [`rdf-agraph` documentation][doc]
* [`rdf-agraph` GitHub project][src]

This code is a wrapper around [phifty's `agraph` gem][agraph_gem], which
provides a low-level interface to AllegroGraph over HTTP.

[rdfrb]: http://rdf.rubyforge.org/
[allegrograph]: http://www.franz.com/agraph/allegrograph/
[doc]: http://rdf-agraph.rubyforge.org/
[src]: https://github.com/emk/rdf-agraph
[agraph_gem]: https://github.com/phifty/agraph

## Installing

To install the `rdf-agraph` gem, run:

    sudo gem install rdf-agraph

To use it from a script, you'll need to require it as follows:

    require 'rubygems'
    gem 'rdf-agraph'
    require 'rdf-agraph'

### Installing with Bundler

If you're using Rails 3 or [Bundler][bundler], add the following line to
your Gemfile:

    gem 'rdf-agraph'

And run:

    bundle install

[bundler]: http://gembundler.com/

## Examples

### Connecting to a repository

To connect to an AllegroGraph repository, call:

    url = "http://user:passwd@localhost:10035/repositories/example"
    repo = RDF::AllegroGraph::Repository.new(url, :create => true)

### Loading data

You may now load an entire file of RDF statements:

    require 'rdf/ntriples'
    repo.load('triples.nt')

You may also insert statements manually with `insert`:

    # Define some useful RDF vocabularies.
    FOAF = RDF::FOAF  # Standard "friend of a friend" vocabulary.
    EX = RDF::Vocabulary.new("http://example.com/")
    
    # Insert triples into AllegroGraph.
    repo.insert(
      # Information about Sam.
      [EX.sam,     RDF.type,   FOAF.Person],
      [EX.sam,     FOAF.name,  'Sam Smith'],
      [EX.sam,     FOAF.mbox,  'mailto:sam@example.com'],
    
      # Information about Susan.
      [EX.susan,   RDF.type,   FOAF.Person],
      [EX.susan,   FOAF.name,  'Susan Jones'],
    
      # Some more people so we have a nice graph.
      [EX.rachel,  RDF.type,   FOAF.Person],
      [EX.richard, RDF.type,   FOAF.Person],
      [EX.mike,    RDF.type,   FOAF.Person],
    
      # Who knows who?
      [EX.sam,     FOAF.knows, EX.susan],
      [EX.susan,   FOAF.knows, EX.rachel],
      [EX.susan,   FOAF.knows, EX.richard],
      [EX.rachel,  FOAF.knows, EX.mike],
      [EX.sam,     FOAF.knows, EX.richard]
    )

### Basic queries

To query for all statements about a subject, try:

    repo.query(:subject => EX.susan) do |statement|
      puts statement
    end
    
    # This prints:
    #   <http://example.com/susan> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .
    #   <http://example.com/susan> <http://xmlns.com/foaf/0.1/name> Susan Jones .
    #   <http://example.com/susan> <http://xmlns.com/foaf/0.1/knows> <http://example.com/rachel> .
    #   <http://example.com/susan> <http://xmlns.com/foaf/0.1/knows> <http://example.com/richard> .

AllegroGraph also supports fully-optimized queries using RDF.rb's Basic
Graph Patterns.  For example, to query for all people with known names:

    repo.build_query do |q|
      q.pattern [:person, RDF.type,  FOAF.Person]
      q.pattern [:person, FOAF.name, :name]
    end.run do |solution|
      puts "#{solution.name}: #{solution.person}"
    end
    
    # This prints:
    #  Sam Smith: http://example.com/sam
    #  Susan Jones: http://example.com/susan

### Advanced AllegroGraph queries

AllegroGraph has a number of more advanced features, including Prolog-style
queries and support for graph algorithms.  To use these features, you'll
need to open up a dedicated AllegoGraph session.  This requires the
AllegroGraph user privileges *Start sessions* and *Evaluate arbitrary
code*.

    repo.session do |session|
    
      # Create a generator.  This will be used to traverse links between
      # nodes.  It's possible to define a generator using multiple
      # predicates, backwards links, and other options.
      knows = session.generator(:object_of => FOAF.knows)
    
      # Find everybody within two degrees of Sam.
      session.build_query do |q|
        q.ego_group_member EX.sam, 2, knows, :person
      end.run do |solution|
        puts solution.person
      end
    
      # This prints:
      #   http://example.com/sam
      #   http://example.com/rachel
      #   http://example.com/richard
      #   http://example.com/susan
    
      # Find a path from Sam to Mike.
      session.build_query do |q|
        q.breadth_first_search_paths EX.sam, EX.mike, knows, :path
      end.run do |solution|
        puts "Found path:"
        solution.path.each {|p| puts "  #{p}" }
      end
    
      # This prints:
      #   Found path:
      #     http://example.com/sam
      #     http://example.com/susan
      #     http://example.com/rachel
      #     http://example.com/mike
    end

## Related Projects & Documentation

For more ideas, check out the following websites:

* [AllegroGraph documentation][agraph_doc]: Documentation index for
  AllegroGraph.
* [AllegroGraph Social Network Analysis][sna]: A Python tutorial showing
  how to analyze the social networks in *Les Miserables*.
* [RDF.rb][rdfrb]: The RDF.rb API.
* [Spira][spira]: Define Ruby model objects for RDF data.

[agraph_doc]: http://www.franz.com/agraph/support/documentation/v4/
[sna]: http://www.franz.com/agraph/support/documentation/v4/python-tutorial/python-tutorial-40.html#Social Network Analysis
[spira]: http://spira.rubyforge.org/

## Installing AllegroGraph

AllegroGraph runs on 64-bit Intel Linux systems.  Mac and Windows users may
be able to run it inside a virtual machine using [supplied images][vm] and
either VMware Player or VMware Fusion.

You may [download AllegroGraph Free Edition][free] from Franz's web site.
AllegroGraph Free Edition supports up to 50 million triples.  For modern
Linux systems, I recommend installing it from a `*.tar.gz` file, as
described in the [installation instructions][install].

If you install AllegroGraph in `/opt/agraph`, you can control it using the
following script:

    #!/bin/bash
    #
    # Call this script as either 'agraph-service start' or
    # 'agraph-service stop'.
    /opt/agraph/bin/agraph-control --config /opt/agraph/lib/agraph.cfg $1

Save this as `/usr/local/bin/agraph-service` and run:

    chmod +x /usr/local/bin/agraph-service

[vm]: http://www.franz.com/agraph/allegrograph/vm.lhtml
[free]: http://www.franz.com/downloads/clp/ag_survey
[install]: http://www.franz.com/agraph/support/documentation/v4/server-installation.html

## A warning about `fork`

If you use insert statements containing blank nodes into an
RDF::AllegroGraph::Repository, the repository will generate and store a
list of blank node IDs.  If you later call `fork` (perhaps because you are
running Unicorn or Spork), you may cause this cache of unused blank node
IDs to be shared between two different processes.  This may result in blank
node IDs being reused for multiple resources.

To avoid this problem, do not insert statements containing blank nodes
until after you have made any `fork` calls.

## Contributing to rdf-agraph

Your patches are welcome!  You may contribute patches to `rdf-agraph` by
forking the [GitHub repository][src] and sending a pull request to `emk`.

If you're like to get your patches merged very quickly, here's some advice
on constructing the ideal patch:

* Start with something small, if you can: A bug fix, some new Prolog
  functors, or a missing AllegroGraph feature.
* [Format your commit messages][git_commit_message] using the standard
  format used by the Linux kernel, Rails and many other projects.  This
  keeps things tidy and makes your patch easy to review!
* Use the commit message to describe the problem that you're fixing.  Make
  sure that I can understand the problem and why your fix is correct.
  You'd think this was obvious, but I've seen some very mysterious patches
  in the past. :-)
* Provide [RSpec][rspec] specifications for the fix.  This may feel like a
  nuisance, but it ensures that your new feature will still work correctly
  two releases from now!  I can help you with this if you're not familiar
  with RSpec.
* Document any new APIs using [yard][yard].

If you do these things (or at least try), I can merge your patch in about
20 seconds.  If you don't know how to do these things, just do your best,
and I'll be happy to help you through the process.

Thank you for contributing to `rdf-agraph`!

[git_commit_message]: http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html
[rspec]: http://relishapp.com/rspec
[yard]: http://yardoc.org/
