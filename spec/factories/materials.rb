# See README.md for copyright details

FactoryGirl.define do
  factory :material do
    sequence(:name) { |n| "material name #{n}" }
    material_type

    factory :material_with_metadata, parent: :material do
      metadata { build_list :metadatum, 3 }
    end
  end
end