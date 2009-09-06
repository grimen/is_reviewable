# coding: utf-8

module IsReviewable
  module Reviewer
    
    DEFAULT_CLASS_NAME = begin
      if defined?(Account)
        :account
      else
        :user
      end
    rescue
      :user
    end
    
  end
end