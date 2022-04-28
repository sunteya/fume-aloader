class City < ApplicationRecord
  belongs_to :country
  belongs_to :province
end