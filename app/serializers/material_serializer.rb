# See README.md for copyright details

class MaterialSerializer < ActiveModel::Serializer
  attributes  :id, :name, :created_at
  belongs_to  :material_type
  has_many    :metadata
  has_many    :parents
  has_many    :children

  def id
    object.uuid
  end
end
