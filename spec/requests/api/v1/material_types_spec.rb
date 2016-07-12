# See README.md for copyright details

require 'rails_helper'

describe Api::V1::MaterialTypesController, type: :request do
  describe "GET #show" do
    it "should return a serialized material_type instance" do
      material_type = create(:material_type)

      get api_v1_material_type_path(material_type), headers: { "Accept": "application/vnd.api+json"}
      expect(response).to be_success

      json = JSON.parse(response.body, symbolize_names: true)

      expect(json[:data][:id]).to eq(material_type.id.to_s)
      expect(json[:data][:attributes][:name]).to eq(material_type.name)
    end
  end

  describe "GET #index" do
    it "should return a list of serialized material_type instances" do
      material_types = create_list(:material_type, 3)

      get api_v1_material_types_path, headers: { "Accept": "application/vnd.api+json"}
      expect(response).to be_success

      json = JSON.parse(response.body, symbolize_names: true)

      expect(json[:data].count).to eq(material_types.count)

      (0...material_types.count).each do |n|
        expect(json[:data][n][:id]).to eq(material_types[n].id.to_s)
        expect(json[:data][n][:attributes][:name]).to eq(material_types[n].name)
      end
    end
  end

end