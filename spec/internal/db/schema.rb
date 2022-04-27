# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table :buses do |t|
    t.string :manufacturer_name
  end

  create_table :genders do |t|
    t.string :code
  end

  create_table :passengers do |t|
    t.integer :bus_id
    t.integer :gender_id
  end

  create_table :trucks do |t|
    t.string :manufacturer_name
  end

  create_table :licenses do |t|
    t.string :number
    t.integer :vehicle_id
    t.string :vehicle_type
  end
end
