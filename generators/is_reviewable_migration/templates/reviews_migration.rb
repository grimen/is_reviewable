# coding: utf-8

class IsReviewableMigration < ActiveRecord::Migration
  def self.up
    create_table :reviews do |t|
      t.references  :reviewable,    :polymorphic => true
      
      t.references  :reviewer,      :polymorphic => true
      t.string      :ip,            :limit => 24
      
      t.float       :rating
      t.text        :body
      
      #
      # Custom fields goes here...
      # 
      # t.string      :title
      # t.string      :mood
      # ...
      #
      
      t.timestamps
    end
    
    add_index :reviews, :reviewer_id
    add_index :reviews, :reviewer_type
    add_index :reviews, [:reviewer_id, :reviewer_type]
    add_index :reviews, [:reviewable_id, :reviewable_type]
  end
  
  def self.down
    drop_table :reviews
  end
end
