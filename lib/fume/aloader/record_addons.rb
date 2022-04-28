require "active_support/concern"
require_relative "dsl"

module Fume::Aloader
  module RecordAddons
    extend ActiveSupport::Concern

    included do
      attr_accessor :aloader
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