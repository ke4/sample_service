# See README.md for copyright details

require 'rails_helper'

RSpec.describe "Materials", type: :request do
  describe "GET #show" do
    it "should return a serialized material instance" do
      material = create(:material)

      get api_v1_material_path(material.uuid) + '?include=material_type', headers: { "Accept": "application/vnd.api+json"}
      expect(response).to be_success

      material_json = JSON.parse(response.body, symbolize_names: true)

      expect(material_json[:data][:id]).to eq(material.uuid)
      expect(material_json[:data][:attributes][:name]).to eq(material.name)
      expect(material_json[:data][:attributes][:created_at]).to_not be_nil

      material_type_json = material_json[:included].select { |obj| obj[:type] == 'material_types' }[0]
      material_type = material.material_type

      expect(material_type_json[:id]).to eq(material_type.id.to_s)
      expect(material_type_json[:attributes][:name]).to eq(material_type.name)
    end


  end

  describe "GET #index" do
    it "should return a list of serialized material instances" do
      materials = create_list(:material, 3)

      get api_v1_materials_path, headers: { "Accept": "application/vnd.api+json"}
      expect(response).to be_success

      material_json = JSON.parse(response.body, symbolize_names: true)

      expect(material_json[:data].count).to eq(materials.count)
    end

  end

  describe "POST #create" do
    let(:post_material) {
      post api_v1_materials_path,
        {
          params: @material_json.to_json,
          headers: {'Content-Type': 'application/vnd.api+json', "Accept": "application/vnd.api+json"}
        }
    }
    let(:serialized_material_json) {
      JSONAPI::ResourceSerializer.new(
        Api::V1::MaterialResource,
        include: ['material_type', 'metadata']
      ).serialize_to_hash(Api::V1::MaterialResource.new(@material, nil)).tap do |json|
        json[:data].except!("links")
        json[:data]["attributes"]["uuid"] = @material_uuid if (@material_uuid)
      end
    }

    it 'should create a new material' do
      material_type = create(:material_type)

      @material = build(:material, material_type: material_type)

      @material_json = serialized_material_json

      expect { post_material }.to change { Material.count }.by(1)
      expect(response).to be_success

      material_json = JSON.parse(response.body, symbolize_names: true)
      new_material = Material.find_by(uuid: material_json[:data][:id])

      expect(material_json[:data][:attributes][:name]).to eq(@material.name)
      expect(new_material.material_type).to eq(material_type)
    end

    it "should create a material instance when a UUID is provided" do
      material_type = create(:material_type)
      @material = build(:material, material_type: material_type)
      @material_uuid = "c317e710-297d-0134-035e-2cbc32c89153"
      @material_json = serialized_material_json

      expect { post_material }.to  change { Material.count }.by(1)
      expect(response).to be_success

      material_json = JSON.parse(response.body, symbolize_names: true)
      new_material = Material.find_by(uuid: material_json[:data][:id])

      expect(material_json[:data][:attributes][:name]).to eq(@material.name)
      expect(material_json[:data][:id]).to eq(@material_uuid)
      expect(new_material.material_type).to eq(material_type)
    end

    it 'should return an error if posting an invalid uuid' do
      material_type = create(:material_type)
      @material = build(:material, material_type: material_type)
      @material_uuid = 'wibble'
      @material_json = serialized_material_json
      
      post_material
      expect(response).to be_unprocessable
      
      material_json = JSON.parse(response.body, symbolize_names: true)
      
      expect(material_json).to include(:errors)
      
      uuid_error_str = material_json[:errors].select { |obj| obj[:title] == 'is not a valid UUID' }[0]
      expect(uuid_error_str[:detail]).to include('is not a valid UUID')
    end

    it "should create a material instance with metadata" do
      # TODO write the test for it
    end
  end

  describe "PUT #update" do
    let(:update_material) {
      put api_v1_material_path(@material.uuid),
        {
          params: @material_json.to_json,
          headers: {'Content-Type': 'application/vnd.api+json', "Accept": "application/vnd.api+json"}
        }
    }
    let(:serialized_material_json) {
      JSONAPI::ResourceSerializer.new(
        Api::V1::MaterialResource,
        include: ['material_type', 'metadata']
      ).serialize_to_hash(Api::V1::MaterialResource.new(@material, nil)).tap do |json|
        json[:data].except!("links")
        json.except!(:included)

        json[:data]["attributes"] = {}
        json[:data]["attributes"]["name"] ||= @new_name if (@new_name)
        json[:data]["attributes"]["uuid"] ||= @new_uuid if (@new_uuid)

        json[:data]["relationships"]["material_type"][:data].merge!({"id" => MaterialType.find_by(name: @new_material_type.name).id }) if (@new_material_type)
      end
    }

    it 'should update the attributes and material_type' do
      @material = create(:material)
      @new_material_type = create(:material_type)
      @new_name = 'new name'
      @new_uuid = UUID.new.generate

      @material_json = serialized_material_json

      expect { update_material }.to  change { Material.count }.by(0)
                                .and change { MaterialType.count }.by(0)

      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to be_success
      expect(response_json[:data][:id]).to eq(@new_uuid)
      expect(response_json[:data][:attributes][:name]).to eq(@new_name)

      @material.reload

      expect(@material.name).to eq(@new_name)
      expect(@material.uuid).to eq(@new_uuid)
      expect(@material.material_type).to eq(@new_material_type)
    end

    it 'should keep the old attributes if none are provided' do
      @material = create(:material)
      old_name = @material.name
      @new_uuid = UUID.new.generate

      @material_json = serialized_material_json

      expect { update_material }.to  change { Material.count }.by(0)

      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to be_success

      expect(response_json[:data][:id]).to eq(@new_uuid)
      expect(response_json[:data][:attributes][:name]).to eq(old_name)

      @material.reload

      expect(@material.name).to eq(old_name)
      expect(@material.uuid).to eq(@new_uuid)
    end

    it 'should not update material when invalid UUID provided' do
      @material = create(:material)
      @new_uuid = "1234"

      @material_json = serialized_material_json

      expect { update_material }.to  change { Material.count }.by(0)

      expect(response).to be_unprocessable
      
      material_json = JSON.parse(response.body, symbolize_names: true)
      
      expect(material_json).to include(:errors)
      
      uuid_error_str = material_json[:errors].select { |obj| obj[:title] == 'is not a valid UUID' }[0]
      expect(uuid_error_str[:detail]).to include('is not a valid UUID')
    end
  end
end
