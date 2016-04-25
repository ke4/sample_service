class CreateMaterialDerivatives < ActiveRecord::Migration[5.0]
  def change
    create_table :material_derivatives do |t|
      t.references :parent, index: true
      t.references :child, index: true
    end
  end
end
