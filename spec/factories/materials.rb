# See README.md for copyright details

FactoryGirl.define do
  factory :material do
    sequence(:name) { |n| "material name #{n}" }
    material_type
  end
end
