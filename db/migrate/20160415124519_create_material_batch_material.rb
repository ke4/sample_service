class CreateMaterialBatchMaterial < ActiveRecord::Migration[5.0]
  def change
    create_table :material_batches_materials do |t|
      t.belongs_to :material, index: true
      t.belongs_to :material_batch, index: true

      t.timestamps
    end
  end
end
