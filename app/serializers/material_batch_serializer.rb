class MaterialBatchSerializer < ActiveModel::Serializer
  has_many    :materials

  def id
    nil
  end
end
