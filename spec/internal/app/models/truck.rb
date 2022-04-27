class Truck < ApplicationRecord
  has_one :license, as: :vehicle
end