class MaterialBatch < ApplicationRecord
  has_many :material_batches_materials
  has_many :materials, through: :material_batches_materials

  validates :materials, presence: true
  validate :check_materials_added, if: '!materials_added.nil?'
  attr_accessor :materials_added

  accepts_nested_attributes_for :materials

  def bulk_save
    return false unless self.valid?

    metadata = materials.flat_map { |m| m.metadata }

    ActiveRecord::Base.transaction do
      insert = MaterialBatch.import [self], validate: false
      self.id = MaterialBatch.last.id

      insert = Material.import materials.to_a, validate: false
      added_materials = Material.last(materials.size)
      materials.zip(added_materials).each { |m, add_m|
        m.id = add_m.id
        m.metadata.each{ |metadatum| metadatum.material_id = m.id }
      }
      Metadatum.import metadata, validate: false

      material_batches_materials = materials.map { |material| MaterialBatchesMaterial.new(material_batch_id: id, material_id: material.id) }
      MaterialBatchesMaterial.import material_batches_materials, validate: false

      material_derivatives = materials.flat_map { |material|
        material.parents.map { |parent| MaterialDerivative.new(parent_id: parent.id, child_id: material.id) }
      }
      MaterialDerivative.import material_derivatives, validate: false
    end

    true
  end

  private

  def check_materials_added
    if materials_added > 0
      errors.add :materials, I18n.t('errors.messages.add_to_batch')
    end
  end
end
