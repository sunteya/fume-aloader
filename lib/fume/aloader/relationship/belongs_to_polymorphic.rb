require_relative "base"

module Fume::Aloader
  module Relationship
    class BelongsToPolymorphic < Base
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
          hash[type] ||= Set.new

          value = record.read_attribute(reflection.join_foreign_key)
          hash[type] << value if !value.nil?
        end


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
    end
  end
end