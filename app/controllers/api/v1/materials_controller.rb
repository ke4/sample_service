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

    material_type = MaterialType.find_by(material_type_create_params)
    metadata = metadata_create_params[:metadata].nil? ? [] : metadata_create_params[:metadata][:data].map { |metadatum| Metadatum.new(metadatum[:attributes]) }
    @material = Material.new(material_create_params.merge(material_type: material_type, metadata: metadata))

    if @material.save
      render json: @material, status: :created, include: [:material_type, :metadata]
    else
      render json: @material.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /materials/1
  def update
    material_type = @material.material_type
    unless material_type_update_params[:relationships].nil? or material_type_update_params[:relationships][:material_type].nil?
      material_type = MaterialType.find_by(material_type_update_params[:relationships][:material_type][:data][:attributes])
    end

    begin
      ActiveRecord::Base.transaction do
        if metadata_update_params[:relationships] and metadata_update_params[:relationships][:metadata]
          metadata_update_params[:relationships][:metadata][:data].each do |new_metadatum|
            metadatum = @material.metadata.find{ |metadatum| metadatum.key == new_metadatum[:attributes][:key] }
            if metadatum.nil?
              @material.metadata << Metadatum.new(new_metadatum[:attributes])
            else
              metadatum.value = new_metadatum[:attributes][:value]
            end
          end
        end

        @material.update!((material_update_params[:attributes] or {}).merge(material_type: material_type))
        @material.metadata.each { |metadatum| metadatum.save! }

        render json: @material, include: [:material_type, :metadata]
      end
    rescue
      render json: @material.errors, status: :unprocessable_entity
    end

  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_material
    @material = Material.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def material_create_params
    params.require(:data).require(:attributes).permit(:name, :uuid)
  end

  def material_update_params
    params.require(:data).permit(attributes: [:name, :uuid])
  end

  def material_type_create_params
    params.require(:data).require(:relationships).require(:material_type).require(:data).require(:attributes).permit(:name)
  end

  def material_type_update_params
    params.require(:data).permit(relationships: { material_type: { data: { attributes: [:name ] }}})
  end

  def metadata_create_params
    params.require(:data).require(:relationships).permit(metadata: { data: [ attributes: [:key, :value] ] })
  end

  def metadata_update_params
    params.require(:data).permit(relationships: { metadata: { data: [ attributes: [:key, :value] ] } })
  end
end
