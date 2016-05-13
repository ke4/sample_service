class MaterialBatchSerializer < ActiveModel::Serializer
  attributes  :id, :name, :created_at
  has_many    :materials
end
