class Material < ApplicationRecord

  belongs_to :material_type
  has_many :metadata

  has_many :parent_derivatives, class_name: 'MaterialDerivative', foreign_key: 'child_id', inverse_of: :child
  has_many :parents, through: :parent_derivatives

  has_many :child_derivatives, class_name: 'MaterialDerivative', foreign_key: 'parent_id', inverse_of: :parent
  has_many :children, through: :child_derivatives

  validates :material_type, presence: true
  validates :name, presence: true
  validates :uuid, uuid: true, if: :uuid

  after_validation :generate_uuid, unless: :uuid

  private

  def generate_uuid
    self.uuid = UUID.new.generate
  end
end