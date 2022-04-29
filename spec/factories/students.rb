FactoryBot.define do
  factory :student do
    name { Faker::Name.name }
  end
end