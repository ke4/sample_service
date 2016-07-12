# See README.md for copyright details

class MaterialType < ApplicationRecord
  validates :name, presence: true, uniqueness: true
end
