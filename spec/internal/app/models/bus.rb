class Bus < ApplicationRecord
  has_one :license, as: :vehicle
  belongs_to :manufacturer
  has_many :passengers

  aloader_init do
  end
end