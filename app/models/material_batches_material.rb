# See README.md for copyright details

class MaterialBatchesMaterial < ApplicationRecord
  belongs_to :material
  belongs_to :material_batch
end
