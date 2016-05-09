# See README.md for copyright details
require 'uuid'

class Material < ApplicationRecord
  belongs_to :material_type
  has_many :material_batches_materials
  has_many :material_batches, through: :material_batches_materials
  has_many :metadata, inverse_of: :material

  has_many :parent_derivatives, class_name: 'MaterialDerivative', foreign_key: 'child_id', inverse_of: :child
  has_many :parents, through: :parent_derivatives

  has_many :child_derivatives, class_name: 'MaterialDerivative', foreign_key: 'parent_id', inverse_of: :parent
  has_many :children, through: :child_derivatives

  validates :name, presence: true
  validates :uuid, uuid: true, uniqueness: {case_sensitive: false}, unless: 'uuid.nil?'

  after_validation :generate_uuid, if: "uuid.nil?"

  attr_accessor :expected_parent_uuids
  validate :expected_parents_match, if: :expected_parent_uuids

  accepts_nested_attributes_for :metadata

  private

  def generate_uuid
    self.uuid = UUID.new.generate
  end

  def expected_parents_match
    errors.add :parents, I18n.t('errors.messages.doesnt_exist') unless expected_parent_uuids == parents.map { |parent| parent.uuid }
  end
end
