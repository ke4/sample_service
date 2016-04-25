# See README.md for copyright details

FactoryGirl.define do 
  factory :material_type do
    sequence(:name) { |n| "Material type name #{n}" }
  end
end