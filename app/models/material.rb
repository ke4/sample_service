# See README.md for copyright details

class Material < ApplicationRecord
  belongs_to  :material_type
  has_many    :metadata

  validates   :name, presence: true
  validates   :uuid, presence: true, uuid:true
end
