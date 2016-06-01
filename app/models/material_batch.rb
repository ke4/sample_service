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
          new_key = "materials.#{key}"
          self.errors.add new_key, error unless error.in? self.errors[new_key]
        }
      }
    }

    errors.empty?
  end

  def self.my_new(json_params)
    material_batch = MaterialBatch.new(materials: [])

    if (data = json_params.dig(:data, :relationships, :materials, :data))
      uuid_materials = Material.where(uuid: data.map { |material_json| material_json[:id] }).includes(:metadata, :material_type, :parents)
      parent_uuids = data.flat_map { |material_json| material_json.dig(:relationships, :parents, :data)&.map { |parent_data| parent_data[:id] } }
      uuid_materials += Material.where(uuid: parent_uuids)
      uuid_materials = uuid_materials.group_by { |m| m.uuid }

      data.each { |material_json|
        material = uuid_materials.dig(material_json[:id], 0)

        material_type = material ? material.material_type : nil
        if (material_type_params = material_json.dig(:relationships, :material_type, :data, :attributes))
          material_type = MaterialType.find_by(material_type_params)
        end

        metadata = material ? material.metadata.map { |metadatum| {id: metadatum.id, key: metadatum.key, value: metadatum.value} } : []
        if (metadata_params = material_json.dig(:relationships, :metadata, :data))
          metadata_params.each { |metadatum|
            metadatum = metadatum[:attributes]
            existing_metadatum = metadata.find { |m| m[:key] == metadatum[:key] }
            if existing_metadatum
              existing_metadatum[:value] = metadatum[:value]
            else
              metadata << {key: metadatum[:key], value: metadatum[:value]}
            end
          }
        end

        old_parent_uuids = material ? material.parents.map { |parent| parent.uuid } : []
        new_parent_uuids = []
        if (parent_data = material_json.dig(:relationships, :parents, :data))
          parent_data.each { |parent|
            unless parent[:id].in? old_parent_uuids
              new_parent_uuids << parent[:id]
            end
          }
        end

        material_attributes = (material_json[:attributes] or {}).merge(
            id: material ? material.id : nil,
            uuid: material_json[:id],
            material_type: material_type,
            metadata_attributes: metadata,
            parents: (material ? material.parents : []) + new_parent_uuids.map { |uuid| uuid_materials.dig(uuid, 0) }.reject { |m| m.nil? },
            expected_parent_uuids: old_parent_uuids + new_parent_uuids,
        )

        if material
          material_batch.materials << material
          material.my_assign_attributes(material_attributes)
        else
          material_batch.materials << Material.my_new(material_attributes)
        end
      }
    end

    material_batch
  end

  def save
    return false unless self.valid?

    parent_derivatives = materials.flat_map { |material| material.parent_derivatives }

    ActiveRecord::Base.transaction do
      Material.import materials.select { |m| m.changed? }, validate: false, on_duplicate_key_update: Material.column_names
      materials_to_add = materials.select { |m| m.id.nil? }
      added_materials = Material.last(materials_to_add.size)
      materials_to_add.zip(added_materials).each { |m, add_m|
        m.metadata.each { |metadatum| metadatum.material_id = add_m.id }
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
