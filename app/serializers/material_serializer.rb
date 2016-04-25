# See README.md for copyright details

class MaterialSerializer < ActiveModel::Serializer
  attributes  :id, :name
  belongs_to  :material_type
  has_many    :metadata

  def id
    object.uuid
  end
end
