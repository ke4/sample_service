class Api::V1::MaterialsController < Api::V1::ApplicationController
  before_action :set_material, only: [:show, :update]

  # GET /materials
  def index
    @materials = Material.all

    render json: @materials, include: [:material_type, :metadata]
  end

  # GET /materials/1
  def show
    render json: @material, include: [:material_type, :metadata]
  end

  # POST /materials
  def create

    @material = Material.build_from_params(material_params)

    if @material.save
      render json: @material, status: :created, include: [:material_type, :metadata]
    else
      render json: @material.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /materials/1
  def update
    if @material.update_from_params(material_params)
      render json: @material, include: [:material_type, :metadata]
    else
      render json: @material.errors, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_material
    @material = Material.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def material_params
    params.require(:data)
  end
end
