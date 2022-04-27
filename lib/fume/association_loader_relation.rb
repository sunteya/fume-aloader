require "active_support/concern"

module AssociationLoaderRelation
  extend ActiveSupport::Concern

  attr_reader :association_loader

  def load(*args, &block)
    return super if loaded?

    result = super

    al_init_records

    result
  end

  def spawn(*args)
    result = super
    result.reinit_association_loader(@association_loader)
    result
  end

  def al_init_records
    init_association_loader
    if @association_loader
      @records.each do |record|
        record.association_loader = @association_loader
      end
    end
  end

  def reinit_association_loader(*args)
    @association_loader = nil
    init_association_loader(*args)
  end

  def init_association_loader(parent = nil)
    return if @association_loader
    return unless klass.respond_to?(:build_association_loader)

    @association_loader = klass.build_association_loader(self)
    @association_loader.predata_values = parent.predata_values.dup if parent
  end

  def al_load(*args)
    records.each { |it| it.al_load(*args) }

    self
  end

  def al_data(*args)
    init_association_loader
    @association_loader.predata_all(*args)
    self
  end

  def al_to_scope(preset = :default)
    init_association_loader
    names = @association_loader.build_preset_include_names(preset) || []

    if names.present?
      includes(*names).references(*names)
    else
      self
    end
  end
end
