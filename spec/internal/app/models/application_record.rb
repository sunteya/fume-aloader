class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def al_load(*args)
    self.aloader&.preload(self, *args)
  end

  def al_data(*args)
    self.aloader&.predata_all(*args)
  end
end