# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table :buses do |t|
    t.string :manufacturer_name
  end

  create_table :genders do |t|
    t.string :code
  end

  create_table :countries do |t|
    t.string :name
  end

  create_table :provinces do |t|
    t.string :name
  end

  create_table :cities do |t|
    t.string :name
    t.integer :country_id
    t.integer :province_id
  end

  create_table :passengers do |t|
    t.string :name
    t.integer :bus_id
    t.integer :gender_id
    t.integer :homeplace_id
  end

  create_table :trucks do |t|
    t.string :manufacturer_name
  end

  create_table :licenses do |t|
    t.string :number
    t.integer :vehicle_id
    t.string :vehicle_type
  end


  create_table :students do |t|
    t.string :name
  end

  create_table :clazzs do |t|
    t.string :name
  end

  create_table :clazzs_students, primary_key: false do |t|
    t.integer :student_id
    t.integer :clazz_id
  end

  create_table :blackboards do |t|
    t.integer :clazz_id
  end
end
