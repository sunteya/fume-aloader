class Clazz < ApplicationRecord
  has_and_belongs_to_many :students
  has_one :blackboard
end