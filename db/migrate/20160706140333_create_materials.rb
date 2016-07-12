# See README.md for copyright details

class CreateMaterials < ActiveRecord::Migration[5.0]
  def change
    create_table :materials do |t|
      t.string :name
      t.string :uuid
      t.references :material_type, foreign_key: true

      t.timestamps
    end
  end
end
