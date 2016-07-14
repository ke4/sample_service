# See README.md for copyright details

class Material < ApplicationRecord
  belongs_to :material_type
  has_many   :metadata

  validates :material_type, presence: true
  validates :name, presence: true

  before_validation :generate_uuid
  validates :uuid, uuid: true, if: :uuid

private

  def generate_uuid
    self.uuid ||= UUID.new.generate
  end
end
