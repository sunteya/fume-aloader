FactoryBot.define do
  factory :clazz do
    name { Faker::Team.name }
    blackboard
  end
end