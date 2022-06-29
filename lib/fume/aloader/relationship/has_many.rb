require_relative "base"

module Fume::Aloader
  module Relationship
    class HasMany < Base
      def get_cache_key(record)
        record.send(reflection.join_foreign_key)
      end

      def build_cached_value(values)
        values.each_with_object(Hash.new { [] }) do |it, result|
          key = it.send(reflection.join_primary_key)
          result[key] += [ it ]
        end
      end

      def loader_is_inited?(parent)
        values = parent.send(reflection.name)
        values.nil? || values.empty? || !!values.first.aloader
      end

      def loaders_init(parents, preset)
        values = parents.flat_map { |it| it.send(reflection.name) }.compact
        return [] if !reflection.klass.respond_to?(:al_build)
        loader = reflection.klass.al_build(values, preset: preset, inject: true)

        [ loader ]
      end
    end
  end
end