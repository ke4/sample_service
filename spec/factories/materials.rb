# See README.md for copyright details

FactoryGirl.define do
  factory :material do
    sequence(:name) { |n| "material name #{n}" }
    material_type

    factory :material_with_metadata, parent: :material do
      metadata { build_list :metadatum, 3 }
    end

    factory :material_with_parent, parent: :material do
      parents { build_list :material, 1 }
    end
    factory :material_with_parents, parent: :material do
      parents { build_list :material, 3 }
    end
    factory :material_with_child, parent: :material do
      children { build_list :material, 1 }
    end
    factory :material_with_children, parent: :material do
      children { build_list :material, 3 }
    end
    factory :material_with_parent_and_child, parent: :material do
      parents { build_list :material, 1 }
      children { build_list :material, 1 }
    end
  end
end