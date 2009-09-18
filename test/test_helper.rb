# coding: utf-8
require 'rubygems'

gem 'test-unit',            '= 1.2.3'
gem 'thoughtbot-shoulda',   '>= 2.10.2'
gem 'sqlite3-ruby',         '>= 1.2.0'
gem 'nakajima-acts_as_fu',  '>= 0.0.5'
gem 'jgre-monkeyspecdoc',   '>= 0.9.5'

require 'test/unit'
require 'shoulda'
require 'acts_as_fu'
require 'monkeyspecdoc'

require 'test_helper'

require 'is_reviewable'

build_model :reviews do
  references  :reviewable,    :polymorphic => true
  
  references  :reviewer,      :polymorphic => true
  string      :ip,            :limit => 24
  
  float       :rating
  text        :body
  
  string      :title
  
  timestamps
end

build_model :guests
build_model :users
build_model :accounts
build_model :posts

build_model :reviewable_posts do
  is_reviewable :by => :users, :scale => 1.0..5.0, :step => 0.5, :average_precision => 2, :accept_ip => true
end

build_model :reviewable_articles do
  is_reviewable :by => [:accounts, :users], :scale => [1,2,3], :accept_ip => false
end

build_model :cached_reviewable_posts do
  integer :reviews_count
  integer :average_rating
end