class Api::V1::MaterialBatchesController < Api::V1::ApplicationController
  include MaterialParametersHelper

  # POST /material_batches
  def create
    @material_batch = MaterialBatch.my_new(material_batch_params)

    if @material_batch.bulk_save
      render json: @material_batch, status: :created, include: included_relations_to_render
    else
      render json: @material_batch.errors, status: :unprocessable_entity
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.

  def material_batch_params
    params = (material_batch_json_params.dig(:data, :attributes) or {})

    materials = []
    material_attributes = []
    materials_added = 0
    if (data = material_batch_json_params.dig(:data, :relationships, :materials, :data))
      uuid_materials = Material.where(uuid: data.map {|material_json| material_json[:id]}).includes(:metadata, :material_type, :parents)
      parent_uuids = data.flat_map { |material_json| material_json.dig(:relationships, :parents, :data)&.map { |parent_data| parent_data[:id] } }
      uuid_materials += Material.where(uuid: parent_uuids)
      uuid_materials = uuid_materials.group_by { |m| m.uuid }
      data.each { |material_json|
        material = uuid_materials.dig(material_json[:id], 0)
        material_attributes << build_material_params(material, material_json, uuid_materials).merge(id: material ? material.id : nil)

        if material
          materials << material
        end
      }
    end

    params.merge(materials: materials, materials_attributes: material_attributes, materials_added: materials_added)
  end

  def material_batch_json_params
    params.permit(data: {
        attributes: [
            :name
        ],
        relationships: {
            materials: material_json_schema
        }
    })
  end

  def included_relations_to_render
    [:materials, "materials.material_type", "materials.metadata"]
  end
end
