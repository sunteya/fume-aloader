module Fume::Aloader
  class AssociationLoader
    attr_accessor :klass
    attr_accessor :records
    attr_accessor :presets
    attr_accessor :profile

    attr_accessor :cached_values
    attr_accessor :predata_values

    def initialize(records, klass = nil, &block)
      self.profile = :default
      self.presets = {}
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
      values_scope = apply_association_includes(values_scope, name)
      values_scope = values_scope.limit(nil).offset(0)
      values_scope
    end

    def apply_association_includes(base, name)
      result = base

      columns = build_profile_attribute_includes(name)
      result = result.includes(columns).references(columns) if columns.any?

      result
    end

    def build_profile_attribute_includes(name)
      preset = self.presets[profile] || {}
      includes = find_attribute_includes(preset, name) || []
      return [] if includes.empty?

      except = (self.predata_values[name] || []).map(&:first)
      result = convert_to_includes_hash(includes, [], except)
      simplify_includes_hash(result)
    end

    def build_profile_scope_includes
      preset = self.presets[profile] || {}
      except = self.cached_values.keys.map { |it| [ it] }.to_set
      self.predata_values.each do |name, items|
        items.each do |item|
          except << ([ name ] + item.first)
        end
      end

      result = {}
      roots = [ preset[:scope_includes] || [] ].flatten
      roots.each do |root|
        if root.is_a?(Hash)
          root.each do |(name, value)|
            result.update convert_to_includes_hash({ name => value }, [], except)
          end
        else
          includes = find_attribute_includes(preset, root) || {}
          result.update convert_to_includes_hash({ root => includes }, [], except)
        end
      end

      simplify_includes_hash(result)
    end

    def simplify_includes_hash(includes)
      array = []
      hash = {}

      includes.each do |(key, value)|
        if value.empty?
          array << key
        else
          hash[key] = simplify_includes_hash(value)
        end
      end

      hash.empty? ? array : array + [ hash ]
    end

    def convert_to_includes_hash(item, prefix = [], except = [])
      case item
      when Hash
        item.each_with_object({}) do |(name, value), result|
          path = prefix + [ name ]
          if !except.include?(path)
            result[name] = convert_to_includes_hash(value, path, except)
          end
        end
      when Array
        item.each_with_object({}) do |name, result|
          path = prefix + [ name ]

          if !except.include?(path)
            result[name] = convert_to_includes_hash({}, path, except)
          end
        end
      else
        path = prefix + [ item ]
        except.include?(path) ? {} : { item => Hash.new }
      end
    end

    def apply_scope_includes(base)
      names = build_profile_scope_includes

      if names.any?
        base.includes(*names).references(*names)
      else
        base
      end
    end

    def find_attribute_includes(preset, name)
      attribute = preset.dig(:attributes, name) || {}
      attribute[:scope_includes]
    end

    def active(name)
      self.profile = name
    end
  end
end
