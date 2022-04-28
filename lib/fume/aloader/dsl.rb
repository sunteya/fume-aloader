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

    def attribute(name, options = {}, &block)
      self.config[:attributes] ||= {}
      self.config[:attributes][name] = options

      if block
        dsl = self.class.new(&block)
        self.config[:attributes][name] = self.config[:attributes][name].merge(dsl.config)
      end
    end

    def apply_config(loader)
      loader.presets = self.config[:presets] || {}
      loader.presets[nil] = {
        scope_includes: self.config[:scope_includes] || [],
        attributes: self.config[:attributes] || {}
      }
      loader
    end
  end
end
