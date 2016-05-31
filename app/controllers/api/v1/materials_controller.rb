class Api::V1::MaterialsController < Api::V1::ApplicationController
  before_action :set_material, only: [:show, :update]
  include MaterialParametersHelper

  # POST /materials
  def create
    material_batch = MaterialBatch.my_new(data: { relationships: { materials: { data: [material_json_params[:data]] } } })

    if material_batch.save
      render json: material_batch.materials.first, status: :created, include: included_relations_to_render
    else
      render json: material_batch.materials.first.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /materials/1
  def update
    material_batch = MaterialBatch.my_new(data: { relationships: { materials: { data: [material_json_params[:data].merge(id: @material.uuid)] } } })

    if material_batch.save
      render json: material_batch.materials.first, include: included_relations_to_render
    else
      render json: material_batch.materials.first.errors, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_material
    @material = Material.find_by(uuid: params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def material_json_params
    params.permit(material_json_schema)
  end

  def included_relations_to_render
    [:material_type, :metadata]
  end

  def query_params
    params.slice(:material_type, :name, :created_before, :created_after)
  end
end
