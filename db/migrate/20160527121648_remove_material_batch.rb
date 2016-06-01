class RemoveMaterialBatch < ActiveRecord::Migration[5.0]
  def change
    drop_table :material_batches
    drop_table :material_batches_materials
  end
end
