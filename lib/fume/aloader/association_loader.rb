module Fume::Aloader
  class AssociationLoader
    attr_accessor :klass
    attr_accessor :records
    attr_accessor :presets
    attr_accessor :profile

    attr_accessor :cached_values
    attr_accessor :preload_values

    def initialize(records, klass = nil, &block)
      self.profile = :default
      self.presets = {}
      self.klass = klass || records.klass

      self.cached_values = {}
      self.preload_values = {}
      self.records = records
      instance_exec(&block) if block
    end

    def find_cached_value(record, name)
      association = record.association(name)
      reflection = association.reflection

      key = reflection.collection? ? record.send(:id) : record.send(reflection.join_foreign_key)

      unless self.cached_values.key?(name)
        init_records_value(name)
      end

      self.cached_values[name][key]
    end

    def load(record, name)
      association = record.association(name)
      if association.loaded? && !self.cached_values.key?(name)
        init_records_value(name, ->(scope) {
          values = self.records.flat_map(&name.to_sym).compact
          scope.send(:load_records, values)
          scope.al_init_records
        })
      else
        value = find_cached_value(record, name)
        association.target = value
      end
    end

    def preload_all(*path, values)
      path = [ path ].flatten
      name = path.shift

      if path.size.zero?
        fill_records_value(name, values)
      else
        self.preload_values[name] ||= []
        self.preload_values[name] << [ path, values ]
      end
    end

    def init_records_value(name, callback = nil)
      association = klass.new.association(name)
      values = build_association_values_scope(name, association)
      callback&.(values)

      if self.preload_values.key?(name)
        preload_values[name].each do |args|
          values.al_preload_all(*args)
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
      values_scope = apply_profile_attribute_includes(values_scope, name)
      values_scope = values_scope.limit(nil).offset(0)
      values_scope
    end

    def apply_profile_attribute_includes(base, name)
      preset = self.active_preset
      attribute = preset.dig(:attributes, name) || {}

      if (attr_preset_name = attribute[:preset])
        return base.al_to_scope(attr_preset_name)
      end

      includes = find_attribute_includes(preset, name) || []
      return base if includes.empty?


      except = (self.preload_values[name] || []).map(&:first)
      columns = simplify_includes_hash(convert_to_includes_hash(includes, [], except))

      if columns.any?
        base = base.includes(columns).references(columns)
      else
        base
      end
    end

    def build_profile_scope_includes
      preset = self.active_preset
      except = self.cached_values.keys.map { |it| [ it] }.to_set
      self.preload_values.each do |name, items|
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

    def apply_profile_scope_includes(base)
      names = build_profile_scope_includes

      if names.any?
        base.includes(*names).references(*names)
      else
        base
      end
    end

    def find_attribute_includes(preset, name)
      attribute = preset.dig(:attributes, name) || {}

      attr_preset_name = attribute[:preset]
      return attribute[:scope_includes] || [] if attr_preset_name.nil?

      loader = build_attribute_aloader(name, attr_preset_name)
      loader.build_profile_scope_includes
    end

    def build_attribute_aloader(name, profile)
      association = klass.new.association(name)
      reflection = association.reflection
      loader = reflection.klass.al_build([])
      loader.active(profile)
      loader
    end

    def active(name)
      self.profile = name
    end

    def active_preset
      self.presets[self.profile] || {}
    end

    def spawn_from(parent)
      self.preload_values = parent.preload_values.dup
      self.profile = parent.profile
    end
  end
end
