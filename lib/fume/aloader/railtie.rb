require "rails/railtie"

module Fume::Aloader
  class Railtie < ::Rails::Railtie
    initializer 'fume-aloader.configure_rails_initialization' do |app|
      ::ActiveRecord::Relation.prepend(AssociationLoaderRelation)
    end
  end
end
