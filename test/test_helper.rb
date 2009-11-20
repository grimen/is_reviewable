# coding: utf-8
require 'rubygems'

def smart_require(lib_name, gem_name, gem_version = '>= 0.0.0')
  begin
    require lib_name if lib_name
  rescue LoadError
    if gem_name
      gem gem_name, gem_version
      require lib_name if lib_name
    end
  end
end

smart_require 'test/unit', 'test-unit', '= 1.2.3'
smart_require 'shoulda', 'shoulda', '>= 2.10.0'
smart_require 'redgreen', 'redgreen', '>= 0.10.4'
smart_require 'sqlite3', 'sqlite3-ruby', '>= 1.2.0'
smart_require 'acts_as_fu', 'acts_as_fu', '>= 0.0.5'

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