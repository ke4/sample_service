class Api::V1::MaterialTypesController < Api::V1::ApplicationController
  before_action :set_material_type, only: [:show, :update, :destroy]

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_material_type
      @material_type = MaterialType.find(params[:id])
    end
end
