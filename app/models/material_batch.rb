class MaterialBatch < ApplicationRecord
  has_and_belongs_to_many :materials

  validates :materials, presence: true
end
