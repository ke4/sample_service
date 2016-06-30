class MaterialBatch
  include ActiveModel::Model
  include ActiveModel::Serialization

  attr_accessor :materials
  validates :materials, presence: true
end