# See README.md for copyright details

class CreateMaterials < ActiveRecord::Migration[5.0]
  def change
    create_table :materials do |t|
      t.belongs_to  :material_type
      t.string      :uuid, limit: 36, index: true
      t.string      :name

      t.timestamps
    end
  end
end
