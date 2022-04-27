class Passenger < ApplicationRecord
  belongs_to :gender
  belongs_to :bus
end