# See README.md for copyright details

class Api::V1::Filters::MaterialTypeFilter
  def self.filter(params)
    material_type = MaterialType.find_by(name: params[:type])
    { material_type_id: material_type ? material_type.id : nil }
  end
end