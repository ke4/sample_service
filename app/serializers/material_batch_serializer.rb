class MaterialBatchSerializer < ActiveModel::Serializer
  attributes  :id, :name
  has_many    :materials
end
