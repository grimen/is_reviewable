# coding: utf-8

module IsReviewable
  class Review < ::ActiveRecord::Base
    
    belongs_to :reviewable, :polymorphic => true
    belongs_to :reviewer,   :polymorphic => true
    
    # Order.
    named_scope :in_order,            :order => 'created_at ASC'
    named_scope :most_recent,         :order => 'created_at DESC'
    named_scope :lowest_rating,       :order => 'rating ASC'
    named_scope :highest_rating,      :order => 'rating DESC'
    
    # Filters.
    named_scope :limit,               lambda { |number_of_items| {:limit => number_of_items} }
    named_scope :recent,              lambda { |arg| arg.is_a?(DateTime) ? {:conditions => ['created_at >= ?', arg]} : {:limit => arg.to_i} }
    named_scope :between_dates,       :conditions => lambda { |from_date, to_date| {:created_at => from_date..to_date} }
    named_scope :with_rating,         :conditions => lambda { |rating_value_or_range| {:rating => rating_value_or_range} }
    named_scope :with_a_rating,       :conditions => ['rating IS NOT NULL']
    named_scope :with_a_comment,      :conditions => ['body IS NOT NULL && LENGTH(body) > 0']
    named_scope :of_reviewable_type,  :conditions => lambda { |type| Support.polymorphic_conditions_for(type, :type) }
    named_scope :by_reviewer_type,    :conditions => lambda { |type| Support.polymorphic_conditions_for(type, :type) }
    named_scope :on,                  :conditions => lambda { |reviewable| Support.polymorphic_conditions_for(reviewable) }
    named_scope :by,                  :conditions => lambda { |reviewer| Support.polymorphic_conditions_for(reviewer) }
    
  end
end