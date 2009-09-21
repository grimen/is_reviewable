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
    named_scope :limit,               lambda { |number_of_items|      {:limit => number_of_items} }
    named_scope :since,               lambda { |created_at_datetime|  {:conditions => ['created_at >= ?', created_at_datetime]}
    named_scope :recent,              lambda do |datetime|
                                        if [::ActiveSupport::TimeWithZone, ::DateTime].any? { |c| c.is_a?(arg) }
                                          {:conditions => ['created_at >= ?', arg]}
                                        else
                                          {:limit => arg.to_i}
                                        end
                                      end
    named_scope :between_dates,       lambda { |from_date, to_date|     {:conditions => {:created_at => (from_date..to_date)}} }
    named_scope :with_rating,         lambda { |rating_value_or_range|  {:conditions => {:rating => rating_value_or_range}} }
    named_scope :with_a_rating,       :conditions => ['rating IS NOT NULL']
    named_scope :without_a_rating,    :conditions => ['rating IS NULL']
    named_scope :with_a_body,         :conditions => ['body IS NOT NULL AND LENGTH(body) > 0']
    named_scope :without_a_body,      :conditions => ['body IS NULL OR LENGTH(body) = 0']
    named_scope :complete,            :conditions => ['rating IS NOT NULL AND body IS NOT NULL AND LENGTH(body) > 0']
    named_scope :of_reviewable_type,  lambda { |type|       {:conditions => Support.polymorphic_conditions_for(type, :reviewable, :type)} }
    named_scope :by_reviewer_type,    lambda { |type|       {:conditions => Support.polymorphic_conditions_for(type, :reviewer, :type)} }
    named_scope :on,                  lambda { |reviewable| {:conditions => Support.polymorphic_conditions_for(reviewable, :reviewable)} }
    named_scope :by,                  lambda { |reviewer|   {:conditions => Support.polymorphic_conditions_for(reviewer, :reviewer)} }
    
  end
end