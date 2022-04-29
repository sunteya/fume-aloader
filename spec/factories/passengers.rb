FactoryBot.define do
  factory :passenger do
    gender { Gender.male }
    name { Faker::Name.name }
    association :homeplace, factory: :city
  end
end