FactoryBot.define do
  factory :city do
    name { Faker::Address.city }
    country
  end
end