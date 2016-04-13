class Api::V1::MaterialTypesController < Api::V1::ApplicationController
  before_action :set_material_type, only: [:show, :update, :destroy]

  # GET /material_types
  def index
    @material_types = MaterialType.all

    render json: @material_types
  end

  # GET /material_types/1
  def show
    render json: @material_type
  end

  # POST /material_types
  def create
    @material_type = MaterialType.new(material_type_params)

    if @material_type.save
      render json: @material_type, status: :created, location: @material_type
    else
      render json: @material_type.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /material_types/1
  def update
    if @material_type.update(material_type_params)
      render json: @material_type
    else
      render json: @material_type.errors, status: :unprocessable_entity
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_material_type
      @material_type = MaterialType.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def material_type_params
      params.require(:material_type).permit(:name)
    end
end
