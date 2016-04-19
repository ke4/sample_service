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

    @material = Api::V1::Helpers::MaterialParser.new(params: material_params).build

    if @material.save
      render json: @material, status: :created, include: [:material_type, :metadata]
    else
      render json: @material.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /materials/1
  def update
    ActiveRecord::Base.transaction do
      @material = Api::V1::Helpers::MaterialParser.new(params: material_params, material: @material).update

      if @material.errors.empty?
        render json: @material, include: [:material_type, :metadata]
      else
        render json: @material.errors, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
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
