# See README.md for copyright details

class Metadatum < ApplicationRecord
  belongs_to :material, inverse_of: :metadata

  validates :key, presence: true
end
