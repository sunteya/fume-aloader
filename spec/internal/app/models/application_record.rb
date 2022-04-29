class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def al_load(*args)
    self.aloader&.load(self, *args)
  end

  def al_preload_all(*args)
    self.aloader&.preload_all(*args)
  end
end