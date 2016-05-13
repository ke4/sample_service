class Api::V1::MaterialsController < Api::V1::ApplicationController
  before_action :set_material, only: [:show, :update]
  include MaterialParametersHelper

  # POST /materials
  def create
    @material = Material.new(material_params)

    if @material.save
      render json: @material, status: :created, include: included_relations_to_render
    else
      render json: @material.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /materials/1
  def update
    if @material.update(material_params)
      render json: @material, include: included_relations_to_render
    else
      render json: @material.errors, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_material
    @material = Material.find_by(uuid: params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def material_params
    build_material_params(@material, material_json_params[:data])
  end

  def material_json_params
    params.permit(material_json_schema)
  end

  def included_relations_to_render
    [:material_type, :metadata]
  end

  def query_params
    params.slice(:type, :name, :created_before, :created_after)
  end
end
