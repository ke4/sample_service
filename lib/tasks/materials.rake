namespace :materials do
  desc "create 3 materials for testing"
  task :create => :environment do |t|
    material_type = MaterialType.find_by(name: "sample")
    (1..3).each do |n|
      material = Material.create!(name: "Material name_#{n}", material_type: material_type)
      (1..3).each do |i|
        Metadatum.create!(key: "Metadata key_#{i}", value: "Metadata value_#{i}", material: material)
      end
    end
  end
end