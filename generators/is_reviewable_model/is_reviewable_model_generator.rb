# coding: utf-8

class IsReviewableModelGenerator < Rails::Generator::Base
  
  def manifest
    record do |m|
      m.template 'review_model.rb', File.join('app', 'models', 'review.rb')
    end
  end
  
end