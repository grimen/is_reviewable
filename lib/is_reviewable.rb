# coding: utf-8
require File.join(File.dirname(__FILE__), *%w[is_reviewable review])
require File.join(File.dirname(__FILE__), *%w[is_reviewable reviewable])
require File.join(File.dirname(__FILE__), *%w[is_reviewable reviewer])
require File.join(File.dirname(__FILE__), *%w[is_reviewable support])

module IsReviewable
  
  extend self
  
  InvalidConfigValueError = ::Class.new(::StandardError)
  InvalidReviewerError = ::Class.new(::StandardError)
  InvalidReviewValueError = ::Class.new(::StandardError)
  RecordError = ::Class.new(::StandardError)
  
  @logger = ::Logger.new(STDOUT)
  
  def log(message, level = :info)
    level = :info if level.blank?
    @logger.send(level.to_sym, message)
  end
  
end