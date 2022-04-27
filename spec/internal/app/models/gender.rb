class Gender < ApplicationRecord
  def self.female
    self.where(code: "female").first_or_create!
  end

  def self.male
    self.where(code: "male").first_or_create!
  end
end