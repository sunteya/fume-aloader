require_relative "relationship"

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
      relationship = Relationship.build(klass, name)
      cache_key = relationship.get_cache_key(record)
      self.cached_values[name][cache_key]
    end

    def load(record, name)
      association = record.association(name)
      if self.cached_values.key?(name)
        # prefer use cached value
        association.target = find_cached_value(record, name)
      elsif association.loaded?
        # ignore
      else
        init_records_value(name)
        association.target = find_cached_value(record, name)
      end
    end

    def preload_all(*path, values)
      path = [ path ].flatten
      name = path.shift

      if path.size.zero?
        cache_association_values(name, values)
      else
        self.preload_values[name] ||= []
        self.preload_values[name] << [ path, values ]
      end
    end

    def init_records_value(name)
      values_list = build_association_values_scopes(name)
      values_list.each do |values|
        if self.preload_values.key?(name)
          preload_values[name].each do |args|
            values.al_preload_all(*args)
          end
        end

        cache_association_values(name, values)
      end
    end

    def cache_association_values(name, values)
      relationship = Relationship.build(klass, name)

      if self.cached_values.key?(name)
        self.cached_values[name].update(relationship.build_cached_value(values))
      else
        self.cached_values[name] = relationship.build_cached_value(values)
      end
    end

    def build_association_values_scopes(name)
      relationship = Relationship.build(klass, name)
      values_scopes = relationship.build_values_scopes(records)

      values_scopes.map do |values_scope|
        apply_profile_attribute_includes(values_scope, name)
      end
    end

    def apply_profile_attribute_includes(base, name)
      preset = self.active_preset
      attribute = preset.dig(:attributes, name) || {}

      if (attr_preset_name = attribute[:preset])
        return base.al_to_scope(attr_preset_name)
      end

      includes = find_attribute_includes(preset, name, base.klass) || []
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
          includes = find_attribute_includes(preset, root, nil) || {}
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

    def find_attribute_includes(preset, name, association_klass)
      attribute = preset.dig(:attributes, name) || {}

      attr_preset_name = attribute[:preset]
      return attribute[:scope_includes] || [] if attr_preset_name.nil?

      association_klass ||= klass.new.association(name).reflection.klass
      loader = association_klass.al_build([])
      loader.active(attr_preset_name)
      loader.build_profile_scope_includes
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
