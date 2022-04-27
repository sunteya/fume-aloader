module Fume::Aloader
  class DSL
    attr_accessor :config

    def initialize(&block)
      self.config = {}
      instance_exec &block if block
    end

    def preset(name, &block)
      name = name.to_sym
      dsl = self.class.new(&block)
      self.config[:presets] ||= {}
      self.config[:presets][name] = { scope_includes: [] }.merge(dsl.config)
    end

    def scope_includes(columns)
      self.config[:scope_includes] = columns
    end

    def association(name, options = {}, &block)
      self.config[:associations] ||= {}
      self.config[:associations][name] = options

      if block
        dsl = self.class.new(&block)
        self.config[:associations][name] = self.config[:associations][name].merge(dsl.config)
      end
    end

    def apply_config(loader)
      loader.includes = (self.config[:associations] || {}).transform_values do |options|
        options[:scope_includes]
      end.compact

      loader.presets_v1 = (self.config[:presets] || {}).transform_values do |options|
        options[:scope_includes]
      end

      loader
    end
  end
end
