# See README.md for copyright details

class MaterialTypeSerializer < ActiveModel::Serializer
  attributes :id, :name
  # TODO make it a full URL
  link :self do
    api_v1_material_type_path(object)
  end
end
