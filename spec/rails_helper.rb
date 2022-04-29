# frozen_string_literal: true
Bundler.require :default, :development
Combustion.initialize! :all

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.before(:suite) { FactoryBot.find_definitions }
end