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

      if path.any?
        value = self.send(name)
        value&.al_load(*path)
      end
    end

    def al_build(preset = :default)
      return self.aloader if self.aloader
      self.aloader = self.class.al_build([ self ])
      self.aloader.active(preset)
    end

    module ClassMethods
      def aloader_init(&block)
        define_singleton_method :al_build do |records|
          dsl = DSL.new(&block)
          dsl.apply_config(AssociationLoader.new(records, self))
        end
      end
    end
  end
end