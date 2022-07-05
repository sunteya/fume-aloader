module Fume::Aloader
  module RelationAddons
    attr_accessor :aloader

    def load(*args, &block)
      return super if loaded?
      result = super
      al_init_records
      result
    end

    def spawn(*args)
      result = super
      result.aloader = nil
      result.al_init_loader
      result.aloader&.spawn_from(self.aloader) if self.aloader
      result
    end

    def al_init_records
      al_init_loader

      if self.aloader
        @records.each do |record|
          record.aloader = self.aloader
        end
      end
    end

    def al_init_loader
      return if self.aloader
      return unless klass.respond_to?(:al_build)

      self.aloader = klass.al_build(self)
    end

    def al_load(*args)
      records.each { |it| it.al_load(*args) }
      self
    end

    def al_preload_all(*args)
      al_init_loader
      self.aloader.preload_all(*args)
      self
    end

    def al_to_scope(preset = :default)
      al_init_loader
      self.aloader.active(preset)
      result = self.aloader.apply_profile_scope_includes(self)
      result
    end
  end
end