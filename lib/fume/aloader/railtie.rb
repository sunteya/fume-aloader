require "rails/railtie"
require_relative "relation_addons"
require_relative "record_addons"

require_relative "association_loader"

module Fume::Aloader
  class Railtie < ::Rails::Railtie
    initializer 'fume-aloader.configure_rails_initialization' do |app|
      ::ActiveRecord::Base.include(RecordAddons)
      ::ActiveRecord::Relation.prepend(RelationAddons)
    end
  end
end
