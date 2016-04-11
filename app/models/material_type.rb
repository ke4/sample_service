# See README.md for copyright details

class MaterialType < ApplicationRecord
  has_many :materials

  validates :name, presence: true
end
