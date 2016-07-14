# See README.md for copyright details

class CreateMetadata < ActiveRecord::Migration[5.0]
  def change
    create_table :metadata do |t|
      t.string :key
      t.string :value
      t.references :material, foreign_key: true

      t.timestamps
    end
  end
end
