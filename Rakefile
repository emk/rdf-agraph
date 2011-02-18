require 'rubygems'
require 'bundler'
Bundler.require(:default, :development)

require 'rspec/core/rake_task'

task :default => :spec

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
  spec.rcov_opts = "--exclude spec --exclude #{ENV['HOME']}/.bundler"
end

desc "Build the documentating using Yard"
task :doc do
  sh 'yard'
end

namespace :doc do
  desc "Publish the documentation"
  task :publish => :doc do
    sh 'scp -r doc/yard/* rdf-agraph.rubyforge.org:/var/www/gforge-projects/rdf-agraph/'
  end
end

