class Passenger < ApplicationRecord
  belongs_to :gender
  belongs_to :bus
  belongs_to :homeplace, class_name: "City"
end