require_relative "base_single"

module Fume::Aloader
  module Relationship
    class BelongsToPolymorphic < BaseSingle
      def get_cache_key(record)
        [ record.send(reflection.join_foreign_type), record.send(reflection.join_foreign_key) ]
      end

      def build_cached_value(values)
        values.index_by { |it| [ it.class.to_s, it.id ] }
      end

      def build_values_scopes(records)
        values_mapping = records.each_with_object({}).each do |record, hash|
          type = record.read_attribute(reflection.join_foreign_type)
          next if type.nil?

          value = record.read_attribute(reflection.join_foreign_key)
          if value
            hash[type] ||= Set.new
            hash[type] << value
          end
        end.compact

        values_mapping.map do |type, values|
          values = [ values.to_a ]

          # HACK: 重写第一次取值，升级后可能会报错
          # 不能使用子查询 select, 可能内存占用过多
          value_transformation = ->(val) {
            values.shift || val
          }

          association_scope = ActiveRecord::Associations::AssociationScope.new(value_transformation)

          association = klass.new(reflection.join_foreign_type => type, reflection.join_foreign_key => -1).association(reflection.name)
          values_scope = association.send(:target_scope).merge(association_scope.scope(association))
          values_scope = values_scope.limit(nil).offset(0)
          values_scope
        end
      end

      def build_values_mapping(records)
      end

      def loaders_init(parents, preset)
        values_mapping = parents.each_with_object({}).each do |parent, hash|
          type = parent.read_attribute(reflection.join_foreign_type)
          next if type.nil?

          value = parent.send(reflection.name)
          if value
            hash[type] ||= Set.new
            hash[type] << value
          end
        end.compact

        values_mapping.each do |type, values|
          loader_klass = type.constantize
          next if !loader_klass.respond_to?(:al_build)
          loader = loader_klass.al_build(values, preset: preset, inject: true)

          loader
        end
      end
    end
  end
end