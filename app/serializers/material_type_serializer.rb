# See README.md for copyright details

class MaterialTypeSerializer < ActiveModel::Serializer
  attributes :id, :name
  link :self do
    api_v1_material_type_path(object)
  end
end
