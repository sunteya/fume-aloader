require "active_support/concern"
require_relative "dsl"

module Fume::Aloader
  module RecordAddons
    extend ActiveSupport::Concern

    included do
      attr_accessor :aloader
    end

    def al_load(*path)
      path = [ path ].flatten
      name = path.shift
      self.aloader.load(self, name)

      value = self.send(name)

      if path.any?
        value&.al_load(*path)
      end

      value
    end

    def al_build(preset = :default)
      return self.aloader if self.aloader
      self.aloader = self.class.al_build([ self ], preset: preset)
    end

    module ClassMethods
      def aloader_init(&block)
        define_singleton_method :al_build do |records, options = {}|
          dsl = DSL.new(&block)
          loader = dsl.apply_config(AssociationLoader.new(records, { klass: self }.merge(options)))

          loader
        end
      end
    end
  end
end
