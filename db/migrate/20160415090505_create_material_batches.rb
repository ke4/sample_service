class CreateMaterialBatches < ActiveRecord::Migration[5.0]
  def change
    create_table :material_batches do |t|
      t.string :name

      t.timestamps
    end
  end
end
