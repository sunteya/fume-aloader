module Fume::Aloader
  class AssociationLoader
    attr_accessor :scopes
    attr_accessor :includes
    attr_accessor :presets_v1
    attr_accessor :klass

    attr_accessor :cached_values
    attr_accessor :predata_values
    attr_accessor :records

    def initialize(records, klass = nil, &block)
      self.scopes = {}
      self.includes = {}
      self.presets_v1 = {}
      self.klass = klass || records.klass

      self.cached_values = {}
      self.predata_values = {}
      self.records = records
      instance_exec(&block) if block
    end

    def fetch(record, name)
      association = record.association(name)
      reflection = association.reflection

      key = reflection.collection? ? record.send(:id) : record.send(reflection.join_foreign_key)

      unless self.cached_values.key?(name)
        init_records_value(name)
      end

      self.cached_values[name][key]
    end

    def preload(record, *names)
      [ names ].flatten.each do |name|
        association = record.association(name)
        if association.loaded? && !self.cached_values.key?(name)
          init_records_value(name, ->(scope) {
            values = self.records.flat_map(&name.to_sym).compact
            scope.send(:load_records, values)
            scope.al_init_records
          })
        else
          value = fetch(record, name)
          association.target = value
        end
      end
    end

    def preload_all(*args)
      records.each { |record| preload(record, *args) }
    end

    def predata_all(*path, values)
      path = [ path ].flatten
      name = path.shift

      if path.size.zero?
        fill_records_value(name, values)
      else
        self.predata_values[name] ||= []
        self.predata_values[name] << [ path, values ]
      end
    end

    def init_records_value(name, callback = nil)
      association = klass.new.association(name)
      values = build_association_values_scope(name, association)
      callback&.(values)

      if self.predata_values.key?(name)
        predata_values[name].each do |args|
          values.al_data(*args)
        end
      end

      fill_records_value(name, values)
    end

    def fill_records_value(name, values)
      association = klass.new.association(name)
      reflection = association.reflection

      if reflection.collection?
        self.cached_values[name] = values.each_with_object(Hash.new { [] }) do |it, result|
          key = it.send(reflection.join_primary_key)
          result[key] += [ it ]
        end
      elsif reflection.belongs_to?
        self.cached_values[name] = values.index_by(&:id)
      else
        self.cached_values[name] = values.index_by { |it| it.send(reflection.join_primary_key) }
      end
    end

    def build_association_values_scope(name, association)
      reflection = association.reflection

      # HACK: 重写第一次取值，升级后可能会报错
      # 不能使用子查询 select, 可能内存占用过多
      hack_values = [ records.map { |item| item.read_attribute(reflection.join_foreign_key) }.uniq ]

      value_transformation = ->(val) {
        hack_values.shift || val
      }

      association_scope = ActiveRecord::Associations::AssociationScope.new(value_transformation)
      values_scope = association.send(:target_scope).merge(association_scope.scope(association))
      values_scope = apply_association_scopes(values_scope, name)
      values_scope = apply_association_includes(values_scope, name)
      values_scope = values_scope.limit(nil).offset(0)
      values_scope
    end

    def apply_association_scopes(scope, name)
      return scope unless self.scopes[name]

      scope.instance_exec(&self.scopes[name]) || scope
    end

    def apply_association_includes(scope, name)
      include_names = self.includes[name]
      return scope unless include_names

      if self.predata_values.key?(name)
        exclude_names = self.predata_values[name].map { |(path, _value)| path.length == 1 ? path.first : nil }
        include_names = build_association_include_names(include_names, exclude_names)
      end
      scope.includes(include_names).references(include_names)
    end

    def build_association_include_names(sources, excludes)
      sources = [ sources ].flatten
      excludes = [ excludes ].flatten.compact

      sources.map do |source|
        if source.is_a?(Hash)
          source.reject { |k, v| excludes.include?(k) }
        elsif excludes.include?(source)
          nil
        else
          source
        end
      end.compact
    end

    def build_preset_include_names(key)
      names = self.presets_v1[key] || []
      names -= self.cached_values.keys

      names.map do |name|
        if self.includes.key?(name)
          { name => self.includes[name] }
        else
          name
        end
      end
    end
  end
end
