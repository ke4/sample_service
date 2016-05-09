module MaterialParametersHelper
  extend ActiveSupport::Concern

  def build_material_params(material, material_json_params)
    params = (material_json_params[:attributes] or {}).merge(uuid: material_json_params[:id]).delete_if { |k, v| v.nil? }

    material_type = material ? material.material_type : nil
    if material_json_params and
        material_json_params[:relationships] and
        material_json_params[:relationships][:material_type] and
        material_json_params[:relationships][:material_type][:data] and
        material_json_params[:relationships][:material_type][:data][:attributes]
      material_type = MaterialType.find_by(material_json_params[:relationships][:material_type][:data][:attributes])
    end

    metadata = material ? material.metadata.map { |metadatum| {id: metadatum.id, key: metadatum.key, value: metadatum.value} } : []
    if material_json_params and
        material_json_params[:relationships] and
        material_json_params[:relationships][:metadata] and
        material_json_params[:relationships][:metadata][:data]

      material_json_params[:relationships][:metadata][:data].each { |metadatum|
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
    if material_json_params and
        material_json_params[:relationships] and
        material_json_params[:relationships][:parents] and
        material_json_params[:relationships][:parents][:data]
      parent_uuids += material_json_params[:relationships][:parents][:data].map { |parent| parent[:id] }
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