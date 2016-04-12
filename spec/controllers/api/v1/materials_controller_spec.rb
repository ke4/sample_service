require 'rails_helper'

describe Api::V1::MaterialsController, type: :request do
  def validate_material(material_json_data, material)
    expect(material_json_data[:id]).to eq(material.id.to_s)
    expect(material_json_data[:attributes][:name]).to eq(material.name)
    expect(material_json_data[:attributes][:uuid]).to eq(material.uuid)
    expect(material_json_data[:relationships][:"material-type"][:data][:id]).to eq(material.material_type.id.to_s)
  end

  def validate_included_material_type(material_type_json, material_type)
    expect(material_type_json[:id]).to eq(material_type.id.to_s)
    expect(material_type_json[:attributes][:name]).to eq(material_type.name)
    expect(material_type_json[:links][:self]).to eq("/api/v1/material_types/#{material_type.id}")
  end

  describe "GET #show" do
    it "should return a serialized material instance" do
      material = create(:material)

      get api_v1_material_path(material)
      expect(response).to be_success

      material_json = JSON.parse(response.body, symbolize_names: true)

      validate_material(material_json[:data], material)

      material_type_json = material_json[:included].select { |obj| obj[:type] == 'material-types' }[0]

      validate_included_material_type(material_type_json, material.material_type)
    end
  end

  describe "GET #index" do
    it "should return a list of serialized material instances" do
      materials = create_list(:material, 3)

      get api_v1_materials_path
      expect(response).to be_success

      material_json = JSON.parse(response.body, symbolize_names: true)

      expect(material_json[:data].count).to eq(materials.count)

      (0...materials.count).each do |n|

        validate_material(material_json[:data][n], materials[n])

        material_type_json = material_json[:included].select { |obj| 
          obj[:type] == 'material-types' and obj[:id] == material_json[:data][n][:relationships][:"material-type"][:data][:id] }[0]

        validate_included_material_type(material_type_json, materials[n].material_type)
      end
    end
  end

end