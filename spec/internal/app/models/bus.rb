class Bus < ApplicationRecord
  has_one :license, as: :vehicle
  has_many :passengers

  aloader_init do
  end
end