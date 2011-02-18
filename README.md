# rdf-agraph: AllegroGraph adapter for RDF.rb



This code is a wrapper around [phifty's `agraph` gem].

[agraph]: https://github.com/phifty/agraph

## Examples

To connect to an AllegroGraph repository, call:

    url = "http://user:passwd@localhost:10035/repositories/example"
    repo = RDF::AllegroGraph::Repository.new(url, :create => true)

You may now load an entire file of RDF statements:

    require 'rdf/ntriples'
    repo.load('triples.nt')

To insert statements manually, call `insert`:

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

AllegroGraph has a number of more advanced features, including Prolog-style
queries and support for graph algorithms.  To use these features, you'll
need to open up a dedicated AllegoGraph session.  This requires the user
privileges *Start sessions* and *Evaluate arbitrary code*.

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

For more ideas, check out the following websites:

* [RDF.rb][rdfrb]: The full RDF.rb API.
* [Spira][spira]: Define Ruby model objects for RDF data.

[rdfrb]: http://rdf.rubyforge.org/
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
