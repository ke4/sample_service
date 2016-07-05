ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

Dir[Rails.root.join("spec/shared/**/*.rb")].each { |f| require f }

class ActiveSupport::TestCase
  include FactoryGirl::Syntax::Methods

  Dir[Rails.root.join("spec/shared/**/*.rb")].each { |f|
    include f.split('/').last.gsub(".rb", "").camelize.constantize
  }

  fixtures :all
end