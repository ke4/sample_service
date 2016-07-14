# See README.md for copyright details

class Metadatum < ApplicationRecord
  belongs_to :material

  validates :key, presence: true, uniqueness: { scope: :material }
  validates :material, presence: true
end
