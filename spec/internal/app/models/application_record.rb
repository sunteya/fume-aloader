class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  attr_accessor :association_loader

  def al_load(*args)
    self.association_loader&.preload(self, *args)
  end

  def al_data(*args)
    self.association_loader&.predata_all(*args)
  end
end