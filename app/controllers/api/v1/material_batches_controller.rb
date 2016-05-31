class Api::V1::MaterialBatchesController < Api::V1::ApplicationController
  include MaterialParametersHelper

  # POST /material_batches
  def create
    @material_batch = MaterialBatch.my_new(material_batch_json_params)

    if @material_batch.save
      render json: @material_batch, status: :created, include: included_relations_to_render
    else
      render json: @material_batch.errors, status: :unprocessable_entity
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.

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
