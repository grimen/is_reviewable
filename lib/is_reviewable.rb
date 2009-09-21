# coding: utf-8
require File.join(File.dirname(__FILE__), *%w[is_reviewable review])
require File.join(File.dirname(__FILE__), *%w[is_reviewable reviewable])
require File.join(File.dirname(__FILE__), *%w[is_reviewable reviewer])
require File.join(File.dirname(__FILE__), *%w[is_reviewable support])

module IsReviewable
  
  extend self
  
  class IsReviewableError < ::StandardError
    def initialize(message)
      ::IsReviewable.log message, :debug
      super message
    end
  end
  
  InvalidConfigValueError = ::Class.new(IsReviewableError)
  InvalidReviewerError = ::Class.new(IsReviewableError)
  InvalidReviewValueError = ::Class.new(IsReviewableError)
  RecordError = ::Class.new(IsReviewableError)
  
  mattr_accessor :verbose
  
  @@verbose = ::Object.const_defined?(:RAILS_ENV) ? (::RAILS_ENV.to_sym == :development) : true
  
  def log(message, level = :info)
    return unless @@verbose
    level = :info if level.blank?
    @@logger ||= ::Logger.new(::STDOUT)
    @@logger.send(level.to_sym, message)
  end
  
end