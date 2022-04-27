class Bus < ApplicationRecord
  has_one :license, as: :vehicle
  has_many :passengers

  def self.build_association_loader(records)
    AssociationLoader.new(records) do
    end
  end
end