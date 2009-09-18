module IsReviewable
  module Support
    
    extend self
    
    # Shortcut method for generating conditions hash for polymorphic belongs_to-associations.
    #
    def polymorphic_conditions_for(object_or_type, field, *match)
      match = [:id, :type] if match.blank?
      # Note: {} is equivalent to Hash.new which takes a block, so we must do: ({}) or (Hash.new)
      returning({}) do |conditions|
        conditions.merge!(:"#{field}_id" => object_or_type.id) if object_or_type.is_a?(::ActiveRecord::Base && match.include?(:id)
        
        if match.include?(:type)
          type = case object_or_type
          when ::Class
            object_or_type.name
          when ::Symbol, ::String
            object_or_type.to_s.singularize.classify
          else # Object - or raise NameError as usual
            object_or_type.class.name
          end
          conditions.merge!(:"#{field}_type" => type)
        end
      end
    end
    
    # Check if object is a valid activerecord object.
    #
    def is_active_record?(object)
      object.present? && object.is_a?(::ActiveRecord::Base) # TODO: ::ActiveModel if Rails 3?
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