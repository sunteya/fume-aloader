module Fume::Aloader
  module Relationship
    class Base
      attr_accessor :klass
      attr_accessor :association
      attr_accessor :reflection

      def initialize(klass, association, reflection)
        self.klass = klass
        self.association = association
        self.reflection = reflection
      end

      def build_values_scopes(records)
        # HACK: 重写第一次取值，升级后可能会报错
        # 不能使用子查询 select, 可能内存占用过多
        hack_values = [ records.map { |item| item.read_attribute(reflection.join_foreign_key) }.uniq ]

        value_transformation = ->(val) {
          hack_values.shift || val
        }

        association_scope = ActiveRecord::Associations::AssociationScope.new(value_transformation)
        values_scope = association.send(:target_scope).merge(association_scope.scope(association))
        values_scope = values_scope.limit(nil).offset(0)
        [ values_scope ]
      end
    end
  end
end