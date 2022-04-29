require_relative "relationship/has_many"
require_relative "relationship/belongs_to"
# require_relative "relationship/has_and_belongs_to_many"
require_relative "relationship/has_one"

module Fume::Aloader
  module Relationship
    def self.build(klass, name)
      association = klass.new.association(name)
      reflection = association.reflection

      reflection_class = nil
      if reflection.through_reflection?
        raise "Not supported through reflection yet"
      elsif reflection.collection?
        reflection_class = HasMany
      elsif reflection.has_one?
        reflection_class = HasOne
      else
        reflection_class = BelongsTo
      end

      reflection_class.new(association, reflection)
    end
  end
end