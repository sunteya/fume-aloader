
FactoryBot.define do
  factory :countries do
    name { Faker::Address.country }
    country
  end
end