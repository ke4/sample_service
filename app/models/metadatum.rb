class Metadatum < ApplicationRecord

  belongs_to :material

  validates :material, presence: true
  validates :key, presence: true

end