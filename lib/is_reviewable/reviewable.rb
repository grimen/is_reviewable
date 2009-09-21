# coding: utf-8

unless defined?(::Review)
  class Review < ::IsReviewable::Review
  end
end

module IsReviewable
  module Reviewable
    
    REVIEW_CLASS      = ::Review
    DEFAULT_SCALE     = 1..5
    DEFAULT_ACCEPT_IP = false
    CACHABLE_FIELDS   = [
        :reviews_count,
        :average_rating
      ].freeze
    ASSOCIATION_FIELDS = [
        :reviewable_id,
        :reviewable_type,
        :reviewer_id,
        :reviewer_type,
        :ip
      ].freeze
    CONTENT_FIELDS = [
        :rating,
        :body
      ].freeze
      
    def self.included(base) #:nodoc:
      base.class_eval do
        extend ClassMethods
      end
      
      # Checks if this object reviewable or not.
      #
      def reviewable?; false; end
      alias :is_reviewable? :reviewable?
    end
    
    module ClassMethods
      
      # TODO: Document this method...thoroughly.
      #
      # Examples:
      #
      #   is_reviewable :by => :user, :scale => 0..5, :total_precision => 2
      #
      def is_reviewable(*args)
        options = args.extract_options!
        options.reverse_merge!(
            :by         => Reviewer::DEFAULT_CLASS_NAME,
            :scale      => options[:values] || options[:range] || DEFAULT_SCALE,
            :accept_ip  => options[:anonymous] || DEFAULT_ACCEPT_IP # i.e. also accepts unique IPs as reviewer
          )
        scale = options[:scale]
        if options[:step].blank? && options[:steps].blank?
          options[:steps] = scale.last - scale.first + 1
        else
          # use :step or :steps beneath
        end
        options[:total_precision] ||= options[:average_precision] || scale.first.to_s.split('.').last.size # == 1
        
        # Check for incorrect input values, and handle ranges of floats with help of :step. E.g. :scale => 1.0..5.0.
        
        if scale.is_a?(::Range) && scale.first.is_a?(::Float)
          options[:step] = (scale.last - scale.first) / (options[:steps] - 1) if options[:step].blank?
          options[:scale] = scale.first.step(scale.last, options[:step]).collect { |value| value }
        else
          options[:scale] = scale.to_a.collect! { |v| v.to_f }
        end
        raise InvalidConfigValueError, ":scale/:range/:values must consist of numeric values only." unless options[:scale].all? { |v| v.is_a?(::Numeric) }
        raise InvalidConfigValueError, ":total_precision must be an integer." unless options[:total_precision].is_a?(::Fixnum)
        
        # Assocations: Review class (e.g. Review).
        options[:review_class] = REVIEW_CLASS
        
        # Reviewer class(es).
        options[:by] = [options[:by]] unless options[:by].is_a?(::Array)
        options[:reviewer_class_names] = options[:by].collect { |class_name| class_name.to_s.singularize.classify }
        options[:reviewer_classes] = options[:reviewer_class_names].collect do |class_name|
          begin
            class_name.constantize
          rescue NameError => e
            raise InvalidReviewerError, "Reviewer class #{options[:reviewer_class_name]} not defined, needs to be defined. #{e}"
          end
        end
        
        # Assocations: Reviewer class(es) (e.g. User, Account, ...).
        options[:reviewer_classes].each do |reviewer_class|
          if ::Object.const_defined?(reviewer_class.name.to_sym)
            reviewer_class.class_eval do
              has_many :reviews, :as => :reviewer, :dependent => :delete_all
              # FIXME: has_many :through relationships through polymorphic relationships not supported by ActiveRecord.
              # Possible solutions: Use gem "has_many_polymorphs", or using proxy objects with gem "roxy".
              #has_many :reviewables, :through => :reviews
            end
          end
        end
        
        # Assocations: Reviewable class (self) (e.g. Page).
        self.class_eval do
          has_many :reviews, :as => :reviewable, :dependent => :delete_all
          # FIXME: has_many :through relationships through polymorphic relationships not supported by ActiveRecord.
          # Possible solutions: Use gem "has_many_polymorphs", or using proxy objects with gem "roxy".
          # has_many :reviewers, :through => :reviews
          
          before_create :init_reviewable_caching_fields
          
          include ::IsReviewable::Reviewable::InstanceMethods
          extend  ::IsReviewable::Reviewable::Finders
        end
        
        # Save the initialized options for this class.
        write_inheritable_attribute :is_reviewable_options, options
        class_inheritable_reader :is_reviewable_options
      end
      
      # Checks if this object reviewable or not.
      #
      def reviewable?
        @@reviewable ||= self.respond_to?(:is_reviewable_options, true)
      end
      alias :is_reviewable? :reviewable?
      
      # The rating scale used for this reviewable class.
      #
      def reviewable_scale
        self.is_reviewable_options[:scale]
      end
      alias :rating_scale :reviewable_scale
      
      # The rating value precision used for this reviewable class.
      #
      # Using Rails default behaviour:
      #
      #   Float#round(<precision>)
      #
      def reviewable_precision
        self.is_reviewable_options[:total_precision]
      end
      alias :rating_precision :reviewable_precision
      
      protected
        
        # Check if the requested reviewer object is a valid reviewer.
        #
        def validate_reviewer(identifiers)
          raise InvalidReviewerError, "Argument can't be nil: no reviewer object or IP provided." if identifiers.blank?
          reviewer = identifiers[:reviewer] || identifiers[:user] || identifiers[:account] || identifiers[:ip]
          is_ip = Support.is_ip?(reviewer)
          reviewer = reviewer.to_s.strip if is_ip
          unless Support.is_active_record?(reviewer) || is_ip
            raise InvalidReviewerError, "Reviewer is of wrong type: #{reviewer.inspect}."
          end
          raise InvalidReviewerError, "Reviewing based on IP is disabled." if is_ip && !self.is_reviewable_options[:accept_ip]
          reviewer
        end
        
    end
    
    module InstanceMethods
      
      # Checks if this object reviewable or not.
      #
      def reviewable?
        self.class.reviewable?
      end
      alias :is_reviewable? :reviewable?
      
      # The rating scale used for this reviewable class.
      #
      def reviewable_scale
        self.class.reviewable_scale
      end
      alias :rating_scale :reviewable_scale
      
      # The rating value precision used for this reviewable class.
      #
      def reviewable_precision
        self.class.reviewable_precision
      end
      alias :rating_precision :reviewable_precision
      
      # Reviewed at datetime.
      #
      def reviewed_at
        self.created_at if self.respond_to?(:created_at)
      end
      
      # Calculate average rating for this reviewable object.
      # 
      def average_rating(recalculate = false)
        if !recalculate && self.reviewable_caching_fields?(:average_rating)
          self.average_rating
        else
          conditions = self.reviewable_conditions(true)
          conditions[0] << ' AND rating IS NOT NULL'
          ::Review.average(:rating,
            :conditions => conditions).to_f.round(self.is_reviewable_options[:total_precision])
        end
      end
      
      # Calculate average rating for this reviewable object within a domain of reviewers.
      #
      def average_rating_by(identifiers)
        # FIXME: Only count non-nil ratings, i.e. See "average_rating".
        ::Review.average(:rating,
            :conditions => self.reviewer_conditions(identifiers).merge(self.reviewable_conditions)
          ).to_f.round(self.is_reviewable_options[:total_precision])
      end
      
      # Get the total number of reviews for this object.
      #
      def total_reviews(recalculate = false)
        if !recalculate && self.reviewable_caching_fields?(:total_reviews)
          self.total_reviews
        else
          ::Review.count(:conditions => self.reviewable_conditions)
        end
      end
      alias :number_of_reviews :total_reviews
      
      # Is this object reviewed by anyone?
      #
      def reviewed?
        self.total_reviews > 0
      end
      alias :is_reviewed? :reviewed?
      
      # Check if an item was already reviewed by the given reviewer or ip.
      #
      # === identifiers hash:
      # * <tt>:ip</tt> - identify with IP
      # * <tt>:reviewer/:user/:account</tt> - identify with a reviewer-model (e.g. User, ...)
      #
      def reviewed_by?(identifiers)
        self.reviews.exists?(:conditions => reviewer_conditions(identifiers))
      end
      alias :is_reviewed_by? :reviewed_by?
      
      # Get review already reviewed by the given reviewer or ip.
      #
      def review_by(identifiers)
        self.reviews.find(:first, :conditions => reviewer_conditions(identifiers))
      end
      
      # View the object with and identifier (user or ip) - create new if new reviewer.
      #
      # === identifiers_and_options hash:
      # * <tt>:reviewer/:user/:account</tt> - identify with a reviewer-model or IP (e.g. User, Account, ..., "128.0.0.1")
      # * <tt>:rating</tt> - Review rating value, e.g. 3.5, "3.5", ... (optional)
      # * <tt>:body</tt> - Review text body, e.g. "Lorem *ipsum*..." (optional)
      # * <tt>:*</tt> - Any custom review field, e.g. :reviewer_mood => "angry" (optional)
      #
      def review!(identifiers_and_options)
        begin
          reviewer = self.validate_reviewer(identifiers_and_options)
          review = self.review_by(identifiers_and_options)
          
          # Except for the reserved fields, any Review-fields should be be able to update.
          review_values = identifiers_and_options.except(*ASSOCIATION_FIELDS)
          review_values[:rating] = review_values[:rating].to_f if review_values[:rating].present?
          
          if review_values[:rating].present? && !self.valid_rating_value?(review_values[:rating])
            ::IsReviewable.log "Invalid rating value: #{review_values[:rating]} not in [#{self.rating_scale.join(', ')}].", :warn
            raise InvalidReviewValueError, "Invalid rating value: #{review_values[:rating]} not in [#{self.rating_scale.join(', ')}]."
          end
          
          unless review.present?
            # An un-existing reviewer of this reviewable object => Create a new review.
            review = ::Review.new do |r|
              r.reviewable_id   = self.id
              r.reviewable_type = self.class.name
              
              if Support.is_active_record?(reviewer)
                r.reviewer_id   = reviewer.id
                r.reviewer_type = reviewer.class.name
              else
                r.ip = reviewer
              end
            end
            self.reviews << review
          else
            # An existing reviewer of this reviewable object => Update the existing review.
          end
          
          # Update non-association attributes, such as rating, body (the review text), and any custom fields.
          review.attributes = review_values.slice(*review.attribute_names.collect { |an| an.to_sym })
          
          if self.reviewable_caching_fields?(:total_reviews)
            begin
              self.cached_total_reviews += 1 if review.new_record?
            rescue
              self.cached_total_reviews = self.total_reviews(true)
            end
          end
          
          if self.reviewable_caching_fields?(:average_rating)
            self.cached_average_rating = self.average_rating(true)
            # new_rating = review.rating - (old_rating || 0)
            # self.cached_average_rating = (self.cached_average_rating + new_rating) / self.cached_total_reviews.to_f
          end
          
          review.save && self.save_without_validation
          review
        rescue InvalidReviewerError, InvalidReviewValueError => e
          raise e
        rescue Exception => e
          ::IsReviewable.log "Could not create/update review #{review.inspect} by #{reviewer.inspect}: #{e}", :warn
          raise RecordError, "Could not create/update review #{review.inspect} by #{reviewer.inspect}: #{e}"
        end
      end
      
      # Remove the review of this reviewer from this object.
      #
      def unreview!(identifiers)
        review = self.review_by(identifiers)
        review_rating = review.rating if review.present?
        
        if review && review.destroy
          if self.reviewable_caching_fields?(:total_reviews)
            begin
              self.cached_total_reviews -= 1
            rescue
              self.cached_total_reviews = self.reviews.size
            end
          end
          
          if self.reviewable_caching_fields?(:average_rating)
            self.cached_average_rating = self.average_rating(true)
            # self.cached_average_rating = (self.cached_average_rating - review_rating) / self.cached_total_reviews.to_f
          end
          
          self.save_without_validation
        else
          ::IsReviewable.log "Could not save review #{review.inspect} by #{reviewer.inspect}: #{e}", :warn
          raise RecordError, "Could not un-review #{review.inspect} by #{reviewer.inspect}: #{e}"
        end
      end
      
      protected
        
        # Checks if a certain value is a valid rating value for this reviewable object.
        #
        def valid_rating_value?(value_or_values)
          value_or_values = [*value_or_values]
          value_or_values.size == (value_or_values & self.rating_scale).size
        end
        alias :valid_rating_values? :valid_rating_value?
        
        # Cachable fields for this reviewable class.
        #
        def reviewable_caching_fields
          CACHABLE_FIELDS
        end
        
        # Checks if there are any cached fields for this reviewable class.
        #
        def reviewable_caching_fields?(*fields)
          fields = CACHABLE_FIELDS if fields.blank?
          fields.all? { |field| self.attributes.has_key?(:"cached_#{field}") }
        end
        alias :has_reviewable_caching_fields? :reviewable_caching_fields?
        
        # Initialize any cached fields.
        #
        def init_reviewable_caching_fields
          self.cached_total_reviews = 0 if self.reviewable_caching_fields?(:cached_total_reviews)
          self.cached_average_rating = 0.0 if self.reviewable_caching_fields?(:average_rating)
        end
        
        def reviewable_conditions(as_array = false)
          conditions = {:reviewable_id => self.id, :reviewable_type => self.class.name}
          as_array ? Support.hash_conditions_as_array(conditions) : conditions
        end
        
        # Generate query conditions.
        #
        def reviewer_conditions(identifiers, as_array = false)
          reviewer = self.validate_reviewer(identifiers)
          if Support.is_active_record?(reviewer)
            conditions = {:reviewer_id => reviewer.id, :reviewer_type => reviewer.class.name}
          else
            conditions = {:ip => reviewer.to_s}
          end
          as_array ? Support.hash_conditions_as_array(conditions) : conditions
        end
        
        def validate_reviewer(identifiers)
          self.class.send(:validate_reviewer, identifiers)
        end
        
    end
    
    module Finders
      
      # When the has-many-through-polymoprhic issue is solved:
      # 
      # * users that reviewed this with rating X
      # * users that reviewed this, also reviewed [...]
      
    end
    
  end
end

# Extend ActiveRecord.
::ActiveRecord::Base.class_eval do
  include ::IsReviewable::Reviewable
end
