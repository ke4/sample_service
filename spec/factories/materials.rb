# See README.md for copyright details

FactoryGirl.define do
  factory :material do
    sequence(:name) { |n| "material name #{n}" }
    material_type

    factory :material_with_metadata do
      after(:build) do |material|
        material.metadata = build_list(:metadatum, 3, material: material)
      end
    end
  end
end
