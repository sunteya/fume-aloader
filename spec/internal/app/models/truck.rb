class Truck < ApplicationRecord
  has_one :license, as: :vehicle
  belongs_to :manufacturer
end