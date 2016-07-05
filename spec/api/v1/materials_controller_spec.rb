require 'rails_helper'

describe Api::V1::MaterialsController, type: :request do
  def validate_material(material_json_data, material)
    expect(material_json_data[:id]).to eq(material.uuid)
    expect(material_json_data[:attributes][:name]).to eq(material.name)
    expect(material_json_data[:attributes][:created_at]).to eq(material.created_at.strftime('%Y-%m-%dT%H:%M:%S.000Z'))
    expect(material_json_data[:attributes][:material_type]).to eq(material.material_type.name)
  end

  def validate_material_with_metadata(material_json_data, material)
    (0...material.metadata.count).each do |n|
      expect(material_json_data[:attributes][:metadata][n][:key]).to eq(material.metadata[n].key)
      expect(material_json_data[:attributes][:metadata][n][:value]).to eq(material.metadata[n].value)
    end
  end

  describe "GET #show" do
    it "should return a serialized material instance" do
      material = create(:material)

      get api_v1_material_path(material.uuid)
      expect(response).to be_success

      material_json = JSON.parse(response.body, symbolize_names: true)

      validate_material(material_json[:data], material)
    end

    it "should return a serialized material instance with metadata" do
      material = create(:material_with_metadata)

      get api_v1_material_path(material.uuid)
      expect(response).to be_success

      material_json = JSON.parse(response.body, symbolize_names: true)

      validate_material(material_json[:data], material)

      validate_material_with_metadata(material_json[:data], material)
    end

    it 'should return a serialized material instance with parents' do
      material = create(:material_with_parents)

      get api_v1_material_path(material.uuid)
      expect(response).to be_success

      material_json = JSON.parse(response.body, symbolize_names: true)

      parents_relationship = material_json[:data][:attributes][:parents]
      expect(parents_relationship.size).to eq(3)

      parents_relationship.zip(material.parents).each { |parent_json, parent|
        expect(parent_json[:id]).to eq(parent.uuid)
      }
    end

    it 'should return a serialized material instance with children' do
      material = create(:material_with_children)

      get api_v1_material_path(material.uuid)
      expect(response).to be_success

      material_json = JSON.parse(response.body, symbolize_names: true)

      children_relationship = material_json[:data][:attributes][:children]
      expect(children_relationship.size).to eq(3)

      children_relationship.zip(material.children).each { |child_json, child|
        expect(child_json[:id]).to eq(child.uuid)
      }
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
      end
    end

    it "should return a list of serialized material instances with metadata" do
      materials = create_list(:material, 3)

      get api_v1_materials_path
      expect(response).to be_success

      materials_json = JSON.parse(response.body, symbolize_names: true)

      expect(materials_json[:data].count).to eq(materials.count)

      (0...materials.count).each do |n|
        material_json = materials_json[:data][n]
        validate_material_with_metadata(material_json, materials[n])
      end
    end

    it 'should only return materials of the correct type' do
      create_list(:material, 3)
      material_type = create(:material_type)
      materials = create_list(:material, 3, material_type: material_type)
      create_list(:material, 3)

      get api_v1_materials_path, filter: {material_type: material_type.name}
      expect(response).to be_success
      materials_json = JSON.parse(response.body, symbolize_names: true)

      expect(materials_json[:data].count).to eq(materials.size)

      materials_json[:data].zip(materials).each { |material_json, material|
        expect(material_json[:id]).to eq(material.uuid)
      }
    end

    it 'should return empty if given invalid type' do
      create_list(:material, 9)

      get api_v1_materials_path, filter: {material_type: "fake_name"}
      expect(response).to be_success
      materials_json = JSON.parse(response.body, symbolize_names: true)

      expect(materials_json[:data].count).to eq(0)
    end

    it 'should return materials of the correct name' do
      create_list(:material, 3)
      material = create(:material)
      create_list(:material, 3)

      get api_v1_materials_path, filter: {name: material.name}
      expect(response).to be_success
      materials_json = JSON.parse(response.body, symbolize_names: true)

      expect(materials_json[:data].count).to eq(1)

      expect(materials_json[:data][0][:id]).to eq(material.uuid)
    end

    it 'should return materials made after the given date' do
      time = Time.now

      old_materials = create_list(:material, 3, created_at: time - 100)
      new_materials = create_list(:material, 3, created_at: time + 100)

      get api_v1_materials_path, filter: {created_after: time}
      expect(response).to be_success
      materials_json = JSON.parse(response.body, symbolize_names: true)

      expect(materials_json[:data].count).to eq(new_materials.size)

      materials_json[:data].zip(new_materials).each { |material_json, material|
        expect(material_json[:id]).to eq(material.uuid)
      }
    end

    it 'should return materials made before the given date' do
      time = Time.now

      old_materials = create_list(:material, 3, created_at: time - 100)
      new_materials = create_list(:material, 3, created_at: time + 100)

      get api_v1_materials_path, filter: {created_before: time}
      expect(response).to be_success
      materials_json = JSON.parse(response.body, symbolize_names: true)

      expect(materials_json[:data].count).to eq(old_materials.size)

      materials_json[:data].zip(old_materials).each { |material_json, material|
        expect(material_json[:id]).to eq(material.uuid)
      }
    end

    it 'should return materials made between the given dates' do
      time = Time.now

      old_materials = create_list(:material, 3, created_at: time - 1000)
      middle_materials = create_list(:material, 3, created_at: time)
      new_materials = create_list(:material, 3, created_at: time + 1000)

      get api_v1_materials_path, filter: {created_after: time - 100, created_before: time + 100}
      expect(response).to be_success
      materials_json = JSON.parse(response.body, symbolize_names: true)

      expect(materials_json[:data].count).to eq(middle_materials.size)

      materials_json[:data].zip(middle_materials).each { |material_json, material|
        expect(material_json[:id]).to eq(material.uuid)
      }
    end
  end

  describe "POST #create" do
    let(:post_material) {
      post api_v1_materials_path, @material_json.to_json, {'Content-Type': 'application/vnd.api+json'}
    }

    it 'should create a new material' do
      material_type = create(:material_type)

      @material_json = {
          data: {
              type: 'materials',
              attributes: {
                  name: 'material_name',
                  material_type: material_type.name
              }
          }
      }

      expect { post_material }.to change { Material.count }.by(1)
                                      .and change { MaterialType.count }.by(0)
                                               .and change { Metadatum.count }.by(0)
      expect(response).to be_success

      new_material = Material.last
      expect(new_material.name).to eq('material_name')
      expect(new_material.material_type).to eq(material_type)
    end

    it 'should create a new material with metadata' do
      material_type = create(:material_type)

      @material_json = {
          data: {
              type: 'materials',
              attributes: {
                  name: 'material_name',
                  material_type: material_type.name,
                  metadata: [
                      {key: 'md_0', value: '123'},
                      {key: 'md_1', value: '456'}
                  ]
              }
          }
      }

      expect { post_material }.to change { Material.count }.by(1)
                                      .and change { MaterialType.count }.by(0)
                                               .and change { Metadatum.count }.by(2)
      expect(response).to be_success

      new_material = Material.last
      expect(new_material.name).to eq('material_name')
      expect(new_material.material_type).to eq(material_type)

      expect(new_material.metadata.size).to eq(2)
      expect(new_material.metadata[0].key).to eq('md_0')
      expect(new_material.metadata[0].value).to eq('123')
      expect(new_material.metadata[1].key).to eq('md_1')
      expect(new_material.metadata[1].value).to eq('456')
    end

    it 'should not create a new material type' do
      @material_json = {
          data: {
              type: 'materials',
              attributes: {
                  name: 'material_name',
                  material_type: 'fake_material'
              }
          }
      }

      expect { post_material }.to change { Material.count }.by(0)
                                      .and change { MaterialType.count }.by(0)
                                               .and change { Metadatum.count }.by(0)
      expect(response).to_not be_success
    end
  end

  describe "PUT #update" do
    let(:update_material) {
      put api_v1_material_path(@material.uuid), @material_json.to_json, {'Content-Type': 'application/vnd.api+json'}
    }

    it 'should be able to update the name' do
      @material = create(:material)

      @material_json = {
          data: {
              id: @material.uuid,
              type: 'materials',
              attributes: {
                  name: "#{@material.name}_changed"
              }
          }
      }

      expect { update_material }.to change { Material.count }.by(0)
                                        .and change { MaterialType.count }.by(0)
                                                 .and change { Metadatum.count }.by(0)
      expect(response).to be_success

      new_material = Material.find(@material.id)

      expect(new_material.name).to eq("#{@material.name}_changed")
    end

    it 'should be able to update the type' do
      @material = create(:material)
      new_material_type = create(:material_type)

      @material_json = {
          data: {
              id: @material.uuid,
              type: 'materials',
              attributes: {
                  material_type: new_material_type.name
              }
          }
      }

      expect { update_material }.to change { Material.count }.by(0)
                                        .and change { MaterialType.count }.by(0)
                                                 .and change { Metadatum.count }.by(0)
      expect(response).to be_success

      new_material = Material.find(@material.id)

      expect(new_material.material_type).to eq(new_material_type)
    end

    it 'should add and update some new metadata' do
      @material = create(:material_with_metadata)

      @material_json = {
          data: {
              id: @material.uuid,
              type: 'materials',
              attributes: {
                  metadata: [
                      {key: @material.metadata[0].key, value: 'updated_value'},
                      {key: 'new_key', value: 'new_value'}
                  ]
              }
          }
      }

      expect { update_material }.to change { Material.count }.by(0)
                                        .and change { MaterialType.count }.by(0)
                                                 .and change { Metadatum.count }.by(1)
      expect(response).to be_success

      new_material = Material.find(@material.id)

      expect(new_material.metadata.size).to eq(@material.metadata.size + 1)
      expect(new_material.metadata[0].key).to eq(@material.metadata[0].key)
      expect(new_material.metadata[0].value).to eq('updated_value')
      expect(new_material.metadata[1].key).to eq(@material.metadata[1].key)
      expect(new_material.metadata[1].value).to eq(@material.metadata[1].value)
      expect(new_material.metadata[2].key).to eq(@material.metadata[2].key)
      expect(new_material.metadata[2].value).to eq(@material.metadata[2].value)
      expect(new_material.metadata[3].key).to eq('new_key')
      expect(new_material.metadata[3].value).to eq('new_value')
    end

    it 'should add and update some new metadata' do
      @material = create(:material_with_metadata)

      @material_json = {
          data: {
              id: @material.uuid,
              type: 'materials',
              attributes: {
                  metadata: [
                      {key: @material.metadata[0].key, value: 'updated_value'},
                      {key: 'new_key', value: 'new_value'}
                  ]
              }
          }
      }

      expect { update_material }.to change { Material.count }.by(0)
                                        .and change { MaterialType.count }.by(0)
                                                 .and change { Metadatum.count }.by(1)
      expect(response).to be_success

      new_material = Material.find(@material.id)

      expect(new_material.metadata.size).to eq(@material.metadata.size + 1)
      expect(new_material.metadata[0].key).to eq(@material.metadata[0].key)
      expect(new_material.metadata[0].value).to eq('updated_value')
      expect(new_material.metadata[1].key).to eq(@material.metadata[1].key)
      expect(new_material.metadata[1].value).to eq(@material.metadata[1].value)
      expect(new_material.metadata[2].key).to eq(@material.metadata[2].key)
      expect(new_material.metadata[2].value).to eq(@material.metadata[2].value)
      expect(new_material.metadata[3].key).to eq('new_key')
      expect(new_material.metadata[3].value).to eq('new_value')
    end

    it 'should not update metadata when there are other errors' do
      @material = create(:material_with_metadata)

      @material_json = {
          data: {
              id: @material.uuid,
              type: 'materials',
              attributes: {
                  material_type: 'fake_material',
                  metadata: [
                      {key: @material.metadata[0].key, value: 'updated_value'},
                      {key: 'new_key', value: 'new_value'}
                  ]
              }
          }
      }

      expect { update_material }.to change { Material.count }.by(0)
                                        .and change { MaterialType.count }.by(0)
                                                 .and change { Metadatum.count }.by(0)
      expect(response).to_not be_success

      new_material = Material.find(@material.id)

      expect(new_material.metadata.size).to eq(@material.metadata.size)
      (0...@material.metadata.size).each { |i|
        expect(new_material.metadata[i].key).to eq(@material.metadata[i].key)
        expect(new_material.metadata[i].value).to eq(@material.metadata[i].value)
      }
    end
  end
end