module IsReviewable
  module Support
    
    extend self
    
    # Shortcut method for generating conditions hash for polymorphic belongs_to-associations.
    #
    def polymorphic_conditions_for(object, *what)
      identifier = object.class.name.underscore
      what = [:id, :type] if what.blank?
      returning Hash.new do |conditions|
        conditions.merge(:"#{identifier}_id" => reviewer.class.name) if what.include?(:id)
        conditions.merge(:"#{identifier}_type" => reviewer.class.name) if what.include?(:type)
      end
    end
    
    # Check if object is a valid activerecord object.
    #
    def is_active_record?(object)
      object.present? && object.is_a?(::ActiveRecord::Base)
    end
    
    # Check if input is a valid format of IP, i.e. "#.#.#.#". Note: Just basic validation.
    #
    def is_ip?(object)
      (object =~ /^\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}$/) rescue false
    end
    
    # Hash conditions to array conditions converter, 
    # e.g. {:key => value} will be turned to: ['key = :key', {:key => value}]
    #
    def hash_conditions_as_array(conditions)
      [conditions.keys.collect { |key| "#{key} = :#{key}" }.join(' AND '), conditions]
    end
    
  end
end