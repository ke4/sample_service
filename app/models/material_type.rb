class MaterialType < ApplicationRecord

  has_many :material

  validates :name, presence: true, uniqueness: true
end