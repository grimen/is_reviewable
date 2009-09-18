# coding: utf-8

class IsReviewableMigrationGenerator < Rails::Generator::Base
  
  def manifest
    record do |m|
      m.migration_template 'reviews_migration.rb',
        File.join('db', 'migrate'), :migration_file_name => 'is_reviewable_migration'
    end
  end
  
end