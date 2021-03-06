class Api::V1::MaterialsController < Api::V1::ApplicationController
  before_action :set_material, only: [:show, :update]

  # GET /materials
  def index
    @materials = Material.all

    render json: @materials, include: includes
  end

  # GET /materials/1
  def show
    render json: @material, include: includes
  end

  # POST /materials
  def create
    @material = Material.build_from_params(material_params)

    if @material.save
      render json: @material, status: :created, include: includes
    else
      render json: @material.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /materials/1
  def update
    if @material.update_from_params(material_params)
      render json: @material, include: includes
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
    params.require(:data)
  end

  def includes
    [:material_type, :metadata]
  end
end
