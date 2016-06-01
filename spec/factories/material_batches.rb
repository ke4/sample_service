FactoryGirl.define do
  factory :material_batch do
    materials { build_list :material, 3 }

    factory :material_batch_with_metadata, parent: :material_batch do
      materials { build_list :material_with_metadata, 3 }
    end
  end
end
