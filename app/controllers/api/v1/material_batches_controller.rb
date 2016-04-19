class Api::V1::MaterialBatchesController < Api::V1::ApplicationController
  before_action :set_material_batch, only: [:show, :update]

  # GET /material_batches
  def index
    @material_batches = MaterialBatch.all

    render json: @material_batches, include: [:materials, "materials.material_type", "materials.metadata"]
  end

  # GET /material_batches/1
  def show
    render json: @material_batch, include: [:materials, "materials.material_type", "materials.metadata"]
  end

  # POST /material_batches
  def create
   @material_batch = MaterialBatch.build_from_params(params)

    if @material_batch.save
      render json: @material_batch, status: :created, include: [:materials, "materials.material_type", "materials.metadata"]
    else
      render json: @material_batch.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /material_batches/1
  def update
    if @material_batch.update_from_params(params)
      render json: @material_batch, status: :created, include: [:materials, "materials.material_type", "materials.metadata"]
    else
      render json: @material_batch.errors, status: :unprocessable_entity
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_material_batch
    @material_batch = MaterialBatch.find(params[:id])
  end
end
