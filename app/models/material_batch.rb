class MaterialBatch < ApplicationRecord
  has_many :material_batches_materials
  has_many :materials, through: :material_batches_materials

  validates :materials, presence: true
  validate :check_materials_added, if: '!materials_added.nil?'
  attr_accessor :materials_added

  accepts_nested_attributes_for :materials

  def bulk_save
    return false unless self.valid?

    ActiveRecord::Base.transaction do
      if self.changed?
        MaterialBatch.import [self], validate: false, on_duplicate_key_update: MaterialBatch.column_names
        self.id ||= MaterialBatch.last.id
      end

      Material.import materials.select { |m| m.changed? }, validate: false, on_duplicate_key_update: Material.column_names
      materials_to_add = materials.select { |m| m.id.nil? }
      added_materials = Material.last(materials_to_add.size)
      materials_to_add.zip(added_materials).each { |m, add_m|
        m.id = add_m.id
        m.metadata.each{ |metadatum| metadatum.material_id = m.id }
      }

      metadata = materials.flat_map { |m| m.metadata }
      Metadatum.import metadata.select { |md| md.changed? }, on_duplicate_key_update: Metadatum.column_names

      material_batches_materials = materials.map { |material|
        material_batches_material = self.material_batches_materials.find { |mbm| mbm.material_batch_id == id and mbm.material_id == material.id }
        (material_batches_material ? material_batches_material : MaterialBatchesMaterial.new(material_batch_id: id, material_id: material.id))
      }
      MaterialBatchesMaterial.import material_batches_materials.select { |mbm| mbm.changed? }

      material_derivatives = materials.flat_map { |material| material.parent_derivatives.each { |pd|
        pd.child_id = material.id
      } }
      MaterialDerivative.import material_derivatives.select { |md| md.changed? }
    end

    true
  end

  def bulk_update(parameters)
    assign_attributes(parameters)

    bulk_save
  end

  private

  def check_materials_added
    if materials_added > 0
      errors.add :materials, I18n.t('errors.messages.add_to_batch')
    end
  end
end
