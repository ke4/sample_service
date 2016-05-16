module MaterialParametersHelper
  extend ActiveSupport::Concern

  def build_material_params(material, material_json_params)
    params = (material_json_params[:attributes] or {}).merge(uuid: material_json_params[:id]).delete_if { |k, v| v.nil? }

    material_type = material ? material.material_type : nil
    if (material_type_params = material_json_params.dig(:relationships, :material_type, :data, :attributes))
      material_type = MaterialType.find_by(material_type_params)
    end

    metadata = material ? material.metadata.map { |metadatum| {id: metadatum.id, key: metadatum.key, value: metadatum.value} } : []
    if (metadata_params = material_json_params.dig(:relationships, :metadata, :data))
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

    parent_uuids = material ? material.parents.map { |parent| parent.uuid } : []
    if (parent_data = material_json_params.dig(:relationships, :parents, :data))
      parent_uuids += parent_data.map { |parent| parent[:id] }
    end

    unless parent_uuids.empty?
      params = params.merge(parents: Material.where(uuid: parent_uuids), expected_parent_uuids: parent_uuids)
    end

    params.merge(material_type: material_type, metadata_attributes: metadata)
  end

  def material_json_schema
    {
        data: [
            :id,
            attributes: [
                :name
            ],
            relationships: {
                material_type: {
                    data: {
                        attributes: [
                            :name
                        ]
                    }
                },
                metadata: {
                    data: [
                        attributes: [
                            :key,
                            :value
                        ]
                    ]
                },
                parents: {
                    data: [
                        :id
                    ]
                }
            }
        ]
    }
  end
end