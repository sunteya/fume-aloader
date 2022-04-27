class License < ApplicationRecord
  belongs_to :vehicle, polymorphic: true
end