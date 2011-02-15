# rdf-agraph: AllegroGraph adapter for RDF.rb

**This code is a work-in-progress!** Your comments and questions are
greatly appreciated, but you probably want to speak to me before using this
code.

## Examples

To connect to an AllegroGraph repository, call:

    repo = RDF::AllegroGraph::Repository.new({
      :host => 'localhost', # Optional.
      :username => 'test',
      :password => 'test',
      :repository => 'example'
    })

You may now load an entire file of RDF statements:

    require 'rdf/ntriples'
    repo.load('triples.nt')

You can also insert statements manually:

    me = RDF::URI('http://example.com/me') 
    FOAF = RDF::FOAF # "Friend of a friend" vocabulary.
    
    repo.insert(
      [me, RDF.type, FOAF.Person],
      [me, FOAF.mbox, 'mailto:me@example.com']
    )

To query for all statements about a subject, try:

    repo.query(:subject => me) do |statement|
      puts "Predicate: #{statement.predicate}  Object: #{statement.object}"
    end
    
    # This prints:
    #   Predicate: http://www.w3.org/1999/02/22-rdf-syntax-ns#type  Object: http://xmlns.com/foaf/0.1/Person
    #   Predicate: http://xmlns.com/foaf/0.1/mbox  Object: mailto:me@example.com

You may also build more elaborate queries:

    query = RDF::Query.new do |q|
      q.pattern [:person, RDF.type, FOAF.Person]
      q.pattern [:person, FOAF.mbox, :email]
    end
    
    repo.query(query) do |solution|
      puts "Person: #{solution.person}  Email: #{solution.email}"
    end
    
    # This prints:
    #   Person: http://example.com/me  Email: mailto:me@example.com

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
