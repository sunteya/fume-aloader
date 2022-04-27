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
      result.al_reinit_loader(self.aloader)
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

    def al_reinit_loader(*args)
      self.aloader = nil
      al_init_loader(*args)
    end

    def al_init_loader(parent = nil)
      return if self.aloader
      return unless klass.respond_to?(:al_build)

      self.aloader = klass.al_build(self)
      self.aloader.predata_values = parent.predata_values.dup if parent
    end

    def al_load(*args)
      records.each { |it| it.al_load(*args) }
      self
    end

    def al_data(*args)
      al_init_loader
      self.aloader.predata_all(*args)
      self
    end

    def al_to_scope(preset = :default)
      al_init_loader
      names = self.aloader.build_preset_include_names(preset) || []

      if names.present?
        includes(*names).references(*names)
      else
        self
      end
    end
  end
end