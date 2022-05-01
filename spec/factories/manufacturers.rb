FactoryBot.define do
  factory :manufacturer do
    name { Faker::Vehicle.manufacture }
  end
end