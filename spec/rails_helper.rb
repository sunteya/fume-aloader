# frozen_string_literal: true
Bundler.require :default, :development
Combustion.initialize! :all

require 'rspec/rails'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.before(:suite) { FactoryBot.find_definitions }
  config.use_transactional_fixtures = true
end