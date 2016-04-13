class Api::V1::MaterialsController < Api::V1::ApplicationController
  before_action :set_material, only: [:show, :update, :destroy]

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

    material_type = MaterialType.find_by(material_type_params)
    metadata = metadata_params[:metadata].nil? ? [] : metadata_params[:metadata][:data].map { |metadatum| Metadatum.new(metadatum[:attributes]) }
    @material = Material.new(material_params.merge(material_type: material_type, metadata: metadata))

    if @material.save
      render json: @material, status: :created, include: [:material_type, :metadata]
    else
      render json: @material.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /materials/1
  def update
    if @material.update(material_params)
      render json: @material
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
    params.require(:data).require(:attributes).permit(:name)
  end

  def material_type_params
    params.require(:data).require(:relationships).require(:material_type).require(:data).require(:attributes).permit(:name)
  end

  def metadata_params
    params.require(:data).require(:relationships).permit(metadata: { data: [ attributes: [:key, :value] ] })
  end
end
