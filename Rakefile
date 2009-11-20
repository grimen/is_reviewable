# coding: utf-8
require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

NAME = "is_reviewable"
SUMMARY = %Q{Rails: Make an ActiveRecord resource ratable/reviewable (rate + text), without the usual extra code-smell.}
HOMEPAGE = "http://github.com/grimen/#{NAME}"
AUTHOR = "Jonas Grimfelt"
EMAIL = "grimen@gmail.com"
SUPPORT_FILES = %w(README.textile)

begin
  gem 'jeweler', '>= 1.0.0'
  require 'jeweler'
  
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = NAME
    gemspec.summary = SUMMARY
    gemspec.description = SUMMARY
    gemspec.homepage = HOMEPAGE
    gemspec.author = AUTHOR
    gemspec.email = EMAIL
    
    gemspec.require_paths = %w{lib}
    gemspec.files = SUPPORT_FILES << %w(MIT-LICENSE Rakefile) << Dir.glob(File.join(*%w[{generators,lib,test} ** *]).to_s)
    gemspec.executables = %w[]
    gemspec.extra_rdoc_files = SUPPORT_FILES
    
    gemspec.add_dependency 'activerecord',  '>= 1.2.3'
    gemspec.add_dependency 'activesupport', '>= 1.2.3'
    
    gemspec.add_development_dependency 'test-unit',     '= 1.2.3'
    gemspec.add_development_dependency 'shoulda',       '>= 2.10.0'
    gemspec.add_development_dependency 'redgreen',      '>= 0.10.4'
    gemspec.add_development_dependency 'sqlite3-ruby',  '>= 1.2.0'
    gemspec.add_development_dependency 'acts_as_fu',    '>= 0.0.5'
  end
  
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler - or one of it's dependencies - is not available. Install it with: sudo gem install jeweler -s http://gemcutter.org"
end

desc %Q{Default: Run unit tests for "#{NAME}".}
task :default => :test

desc %Q{Run unit tests for "#{NAME}".}
Rake::TestTask.new(:test) do |test|
  test.libs << %w[lib test]
  test.pattern = File.join(*%w[test ** *_test.rb])
  test.verbose = true
end

desc %Q{Generate documentation for "#{NAME}".}
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = NAME
  rdoc.options << '--line-numbers' << '--inline-source' << '--charset=UTF-8'
  rdoc.rdoc_files.include(SUPPORT_FILES)
  rdoc.rdoc_files.include(File.join(*%w[lib ** *.rb]))
end
