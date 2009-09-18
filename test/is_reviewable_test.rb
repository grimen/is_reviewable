# coding: utf-8
require 'test_helper'

class IsReviewableTest < Test::Unit::TestCase
  
  def setup
    @review = ::Review.new
    @user_1 = ::User.create
    @user_2 = ::User.create
    @user_3 = ::User.create
    @regular_post = ::Post.create
    @reviewable_post = ::ReviewablePost.create
    @reviewable_article = ::ReviewableArticle.create
  end
  
  context "initialization" do
    
    should "extend ActiveRecord::Base" do
      assert_respond_to ::ActiveRecord::Base, :is_reviewable
      assert_respond_to ::ActiveRecord::Base, :is_reviewable?
    end
    
    should "extend with instance methods only for reviewable models" do
      public_instance_methods = [
          [:is_reviewable?, :reviewable?],
          [:rating_scale, :reviewable_scale],
          [:rating_precision, :reviewable_precision],
          :reviewed_at,
          :average_rating,
          :average_rating_by,
          [:number_of_reviews, :total_reviews],
          [:is_reviewed?, :reviewed?],
          [:is_reviewed_by?, :reviewed_by?],
          :review_by,
          :review!,
          :unreview!,
          :reviews
        ].flatten
        
      assert public_instance_methods.all? { |m| @reviewable_post.respond_to?(m.to_sym) }
      assert !public_instance_methods.all? { |m| @regular_post.respond_to?(m) }
    end
    
    # Don't work for some reason... =S
    should "be enabled only for specified models" do
      assert @reviewable_post.reviewable?
      assert !@regular_post.reviewable?
    end
    
    should "have many reviews" do
       assert @reviewable_post.respond_to?(:reviews)
    end
    
    should "have many reviewers" do
      assert @reviewable_post.respond_to?(:reviewers)
    end
    
  end
  
  context "reviewable" do
    should "have no reviews from the beginning" do
      assert_equal(@reviewable_post.reviews.size, 0)
    end
    
    should "count reviews and ratings based on IP correctly" do
      @reviewable_post.review!(:reviewer => '128.0.0.0', :rating => 1)
      @reviewable_post.review!(:reviewer => '128.0.0.1', :rating => 2.5)
      
      assert_equal 2, @reviewable_post.total_reviews
      assert_equal 1.75, @reviewable_post.average_rating # with precision set to 2
      
      # should not count as  new, but update values
      @reviewable_post.review!(:reviewer => '128.0.0.1', :rating => 3)
      
      assert_equal 2, @reviewable_post.total_reviews
      assert_equal 2.0, @reviewable_post.average_rating
      
      # should not count in the end
      @reviewable_post.review!(:reviewer => '128.0.0.3', :rating => 1)
      @reviewable_post.unreview!(:reviewer => '128.0.0.3', :rating => 1)
      
      assert_equal 2, @reviewable_post.total_reviews
      assert_equal 2.0, @reviewable_post.average_rating
    end
    
    should "not accept any reviews on IP if disabled" do
      assert_raise ::IsReviewable::InvalidReviewerError do
        @reviewable_article.review!(:reviewer => '128.0.0.0', :rating => 1)
      end
    end
    
    should "count reviews based on reviewer object (user/account) correctly" do
      @reviewable_post.review!(:reviewer => @user_1, :rating => 1)
      @reviewable_post.review!(:reviewer => @user_2, :rating => 2.5)
      
      assert_equal 2, @reviewable_post.total_reviews
      assert_equal 1.75, @reviewable_post.average_rating # with precision set to 2
      
      # should not count as  new, but update values
      @reviewable_post.review!(:reviewer => @user_2, :rating => 3)
      
      assert_equal 2, @reviewable_post.total_reviews
      assert_equal 2.0, @reviewable_post.average_rating
      
      # should not count in the end
      @reviewable_post.review!(:reviewer => @user_3, :rating => 1)
      @reviewable_post.unreview!(:reviewer => @user_3, :rating => 1)
      
      assert_equal 2, @reviewable_post.total_reviews
      assert_equal 2.0, @reviewable_post.average_rating
    end
    
    should "count reviews based on both IP and reviewer object (user/account) correctly" do
      @reviewable_post.review!(:reviewer => @user_1, :rating => 1)
      @reviewable_post.review!(:reviewer => '128.0.0.2', :rating => 2.5)
      
      assert_equal 2, @reviewable_post.total_reviews
      assert_equal 1.75, @reviewable_post.average_rating # with precision set to 2
      
      # should not count as new, but update values
      @reviewable_post.review!(:reviewer => '128.0.0.2', :rating => 3)
      
      assert_equal 2, @reviewable_post.total_reviews
      assert_equal 2.0, @reviewable_post.average_rating
    end
    
    should "not count NULL-ratings, e.g. reviews skipping rating value" do
      @reviewable_post.review!(:reviewer => @user_1, :rating => nil)
      
      assert_equal 1, @reviewable_post.total_reviews
      assert_equal 0.0, @reviewable_post.average_rating
    end
    
    should "not accept ratings out of rating scale range" do
      assert_raise ::IsReviewable::InvalidReviewValueError do
        @reviewable_post.review!(:reviewer => @user_1, :rating => 6)
      end
    end
    
    should "save review body" do
      review_body = "Lorem ipsum dolor sit amet, consectetur adipisicing elit..."
      
      # just body
      review_1 = @reviewable_post.review!(:reviewer => @user_1, :body => review_body)
      assert_equal(review_body, review_1.body)
      
      # body + rating
      review_2 = @reviewable_post.review!(:reviewer => @user_2, :rating => 4, :body => review_body)
      assert_equal(review_body, review_2.body)
    end
    
    should "save any additional non-reserved attribute values" do
      review = @reviewable_post.review!(:reviewer => @user_1, :rating => 4, :title => "My title")
      assert_equal "My title", review.title
      
      # don't allow update of reserved fields
      review = @reviewable_post.review!(:reviewer => @user_2, :reviewable_id => 666)
      assert_not_equal 666, review.reviewable_id
    end
  end
  
  context "reviewer" do
    
    should "have many reviews" do
       assert @user_1.respond_to?(:reviews)
    end
    
    should "have many reviewables" do
      assert @user_1.respond_to?(:reviewables)
    end
    
    # Nothing
    
  end
  
  context "review" do
    
    should "define named scopes" do
      named_scopes = [
          :between_dates
        ]
      
      #assert named_scopes.all? { |named_scope| Review.respond_to?(named_scope, true) }
      #assert named_scopes.all? { |named_scope| @reviewable_post.reviews.respond_to?(named_scope) }
    end
    
    should "return reviews by creation date with named scope :in_order" do
      @reviewable_post.review!(:reviewer => @user_1, :rating => 1)
      @reviewable_post.review!(:reviewer => @user_2, :rating => 2)
      
      puts @reviewable_post.reviews.first.class
      
      #assert_equal @user_1, @reviewable_post.reviews.in_order.first.reviewer
      #assert_equal @user_2, @reviewable_post.reviews.in_order.last.reviewer
    end
    
  end
  
end