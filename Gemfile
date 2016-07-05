source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.0'
# Use mysql2 for test and production purposes
gem 'mysql2'

# Use Puma as the app server
gem 'puma', '~> 3.0'

gem 'jsonapi-resources'

# Allows us to use binary uuid columns.
# Currently not working with Rails 5 beta3
#gem 'activeuuid'
gem 'uuid'

# this gem is for bulk saving, but jsonapi-resources is covering this feature
# gem 'activerecord-import'

gem 'ruby-prof'
gem 'rails-perftest'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'simplecov', require: false

  # Use sqlite3 as the database for Active Record
  gem 'sqlite3'
end

group :development do
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
