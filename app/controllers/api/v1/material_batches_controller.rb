class Api::V1::MaterialBatchesController < Api::V1::ApplicationController
  before_action :set_material_batch, only: [:show, :update]
  include MaterialParametersHelper

  # GET /material_batches
  def index
    @material_batches = MaterialBatch.all

    render json: @material_batches, include: includes
  end

  # GET /material_batches/1
  def show
    render json: @material_batch, include: includes
  end

  # POST /material_batches
  def create
    @material_batch = MaterialBatch.new(material_batch_params)

    if @material_batch.bulk_save
      set_material_batch_by_id(@material_batch.id)
      render json: @material_batch, status: :created, include: includes
    else
      render json: @material_batch.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /material_batches/1
  def update
    if @material_batch.bulk_update(material_batch_params)
      set_material_batch_by_id(@material_batch.id)
      render json: @material_batch, include: includes
    else
      render json: @material_batch.errors, status: :unprocessable_entity
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_material_batch
    @material_batch = set_material_batch_by_id(params[:id])
  end

  def set_material_batch_by_id(id)
    @material_batch = MaterialBatch.includes(materials: [:metadata, :material_type, :parents, :children]).find(id)
  end

  def material_batch_params
    params = (material_batch_json_params[:data][:attributes] or {})

    material_ids = @material_batch ? @material_batch.materials.map {|m| m.id} : []
    material_attributes = []
    materials_added = 0
    if material_batch_json_params[:data] and
        material_batch_json_params[:data][:relationships] and
        material_batch_json_params[:data][:relationships][:materials] and
        material_batch_json_params[:data][:relationships][:materials][:data]
      material_batch_json_params[:data][:relationships][:materials][:data].each { |material_json|
        material = material_json[:id] ? Material.find_by(uuid: material_json[:id]) : nil
        material_params = build_material_params(material, material_json).merge(id: material ? material.id : nil)

        if @material_batch
          if @material_batch.materials.include? material
            material_ids << material.id
            material_attributes << material_params
          else
            materials_added += 1
          end
        else
          if material
            material_ids << material.id
          end
          material_attributes << material_params
        end
      }
    end

    params.merge(material_ids: material_ids, materials_attributes: material_attributes, materials_added: materials_added)
  end

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

  def includes
    [:materials, "materials.material_type", "materials.metadata"]
  end
end
