# See README.md for copyright details
require 'uuid'

class Material < ApplicationRecord
  belongs_to :material_type
  has_many :material_batches_materials
  has_many :material_batches, through: :material_batches_materials
  has_many :metadata, inverse_of: :material
  has_and_belongs_to_many :children, class_name: 'Material', join_table: 'material_derivatives', foreign_key: :parent_id, association_foreign_key: :child_id
  has_and_belongs_to_many :parents, class_name: 'Material', join_table: 'material_derivatives', foreign_key: :child_id, association_foreign_key: :parent_id

  validates :name, presence: true
  validates :uuid, uniqueness: {case_sensitive: false}, uuid: true

  after_initialize :generate_uuid, if: "uuid.nil?"

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
