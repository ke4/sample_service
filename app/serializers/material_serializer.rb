# See README.md for copyright details

class MaterialSerializer < ActiveModel::Serializer
  attributes  :id, :uuid, :name
  belongs_to  :material_type
  has_many    :metadata
end
