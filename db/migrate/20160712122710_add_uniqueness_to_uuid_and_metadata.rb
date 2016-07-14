# See README.md for copyright details

class AddUniquenessToUuidAndMetadata < ActiveRecord::Migration[5.0]
  def change
    add_index :materials, :uuid, unique: true
    add_index :metadata, [:key, :material_id], unique: true
  end
end