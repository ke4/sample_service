class MaterialBatch < ApplicationRecord
  has_many :material_batches_materials
  has_many :materials, through: :material_batches_materials

  validates :materials, presence: true
  validate :check_materials_added, if: '!materials_added.nil?'
  attr_accessor :materials_added

  accepts_nested_attributes_for :materials

  private

  def check_materials_added
    if materials_added > 0
      errors.add :materials, I18n.t('errors.messages.add_to_batch')
    end
  end
end
