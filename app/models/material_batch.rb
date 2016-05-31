class MaterialBatch
  include ActiveModel::Model
  include ActiveModel::Serialization

  validates :materials, presence: true
  attr_accessor :materials_added

  attr_accessor :materials
  attr_accessor :materials_attributes

  def valid?
    super()

    self.materials.each { |material|
      material.valid?
      material.errors.each { |key|
        material.errors[key].each { |error|
        self.errors.add "materials.#{key}", error
        }
      }
    }

    errors.empty?
  end

  def self.my_new(params)
    object = MaterialBatch.new(materials: params[:materials])

    id_materials = {}
    object.materials.each { |m|
      id_materials[m.id.to_s] = m
    }
    (params[:materials_attributes] or []).each { |attr|
      if attr.has_key? :id and attr[:id]
        id_materials[attr[:id].to_s].my_assign_attributes(attr)
      else
        object.materials << Material.my_new(attr)
      end
    }

    object
  end

  def bulk_save
    return false unless self.valid?

    parent_derivatives = materials.flat_map { |material| material.parent_derivatives }

    ActiveRecord::Base.transaction do
      Material.import materials.select { |m| m.changed? }, validate: false, on_duplicate_key_update: Material.column_names
      materials_to_add = materials.select { |m| m.id.nil? }
      added_materials = Material.last(materials_to_add.size)
      materials_to_add.zip(added_materials).each { |m, add_m|
        m.metadata.each{ |metadatum| metadatum.material_id = add_m.id }
        m.id = add_m.id
      }

      metadata = materials.flat_map { |m| m.metadata }
      Metadatum.import metadata.select { |md| md.changed? }, validate: false, on_duplicate_key_update: Metadatum.column_names

      material_derivatives = parent_derivatives.each { |pd| pd.child_id = pd.child.id }
      MaterialDerivative.import material_derivatives.select { |md| md.changed? }, validate: false


      self.materials = Material.includes(:metadata, :material_type, :parents, :children).where(id: materials.map { |m| m.id })
    end

    true
  end
end
