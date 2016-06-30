class Api::V1::MaterialsController < Api::V1::ApplicationController
  before_action :set_material, only: [:show, :update]

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_material
    @material = Material.find_by(uuid: params[:id])
  end

  def included_relations_to_render
    [:material_type, :metadata]
  end

  def query_params
    params.slice(:material_type, :name, :created_before, :created_after)
  end
end
