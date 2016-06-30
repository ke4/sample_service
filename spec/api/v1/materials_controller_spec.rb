require 'rails_helper'

describe Api::V1::MaterialsController, type: :request do
  def validate_material(material_json_data, material)
    expect(material_json_data[:id]).to eq(material.uuid)
    expect(material_json_data[:attributes][:name]).to eq(material.name)
    expect(material_json_data[:attributes][:created_at]).to eq(material.created_at.strftime('%Y-%m-%dT%H:%M:%S.000Z'))
    expect(material_json_data[:relationships][:material_type][:data][:id]).to eq(material.material_type.id.to_s)
  end

  def validate_included_material_type(material_type_json, material_type)
    expect(material_type_json[:id]).to eq(material_type.id.to_s)
    expect(material_type_json[:attributes][:name]).to eq(material_type.name)
  end

  def validate_material_with_metadata(material_json_data, material)
    (0...material.metadata.count).each do |n|
      expect(material_json_data[:relationships][:metadata][:data][n][:id]).to eq(material.metadata[n].id.to_s)
    end
  end

  def validate_included_metadata(metadata_json, metadata)
    (0...metadata.count).each do |n|
      metadatum_json = metadata_json.select { |obj| obj[:id] == metadata[n].id.to_s }[0]
      expect(metadatum_json[:attributes][:key]).to eq(metadata[n].key)
      expect(metadatum_json[:attributes][:value]).to eq(metadata[n].value)
    end
  end

  describe "GET #show" do
    it "should return a serialized material instance" do
      material = create(:material)

      get api_v1_material_path(material.uuid)
      expect(response).to be_success

      material_json = JSON.parse(response.body, symbolize_names: true)

      validate_material(material_json[:data], material)

      material_type_json = material_json[:included].select { |obj| obj[:type] == 'material_types' }[0]

      validate_included_material_type(material_type_json, material.material_type)
    end

    it "should return a serialized material instance with metadata" do
      material = create(:material_with_metadata)

      get api_v1_material_path(material.uuid)
      expect(response).to be_success

      material_json = JSON.parse(response.body, symbolize_names: true)

      validate_material(material_json[:data], material)

      validate_material_with_metadata(material_json[:data], material)
      validate_included_metadata(material_json[:included].select { |obj| obj[:type] == 'metadata' }, material.metadata)
    end

    it 'should return a serialized material instance with parents' do
      material = create(:material_with_parents)

      get api_v1_material_path(material.uuid)
      expect(response).to be_success

      material_json = JSON.parse(response.body, symbolize_names: true)

      parents_relationship = material_json[:data][:relationships][:parents][:data]
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

      children_relationship = material_json[:data][:relationships][:children][:data]
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

        material_type_json = material_json[:included].select { |obj|
          obj[:type] == 'material_types' and obj[:id] == material_json[:data][n][:relationships][:"material_type"][:data][:id] }[0]

        validate_included_material_type(material_type_json, materials[n].material_type)
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

        validate_included_metadata(materials_json[:included].select { |obj| obj[:type] == 'metadata' }, materials[n].metadata)
      end
    end

    it 'should only return materials of the correct type' do
      create_list(:material, 3)
      material_type = create(:material_type)
      materials = create_list(:material, 3, material_type: material_type)
      create_list(:material, 3)

      get api_v1_materials_path, { material_type: material_type.name }
      expect(response).to be_success
      materials_json = JSON.parse(response.body, symbolize_names: true)

      expect(materials_json[:data].count).to eq(materials.size)

      materials_json[:data].zip(materials).each { |material_json, material|
        expect(material_json[:id]).to eq(material.uuid)
      }
    end

    it 'should return empty if given invalid type' do
      create_list(:material, 9)

      get api_v1_materials_path, { material_type: "fake_name" }
      expect(response).to be_success
      materials_json = JSON.parse(response.body, symbolize_names: true)

      expect(materials_json[:data].count).to eq(0)
    end

    it 'should return materials of the correct name' do
      create_list(:material, 3)
      material = create(:material)
      create_list(:material, 3)

      get api_v1_materials_path, { name: material.name }
      expect(response).to be_success
      materials_json = JSON.parse(response.body, symbolize_names: true)

      expect(materials_json[:data].count).to eq(1)

      expect(materials_json[:data][0][:id]).to eq(material.uuid)
    end

    it 'should return materials made after the given date' do
      time = Time.now

      old_materials = create_list(:material, 3, created_at: time - 100)
      new_materials = create_list(:material, 3, created_at: time + 100)

      get api_v1_materials_path, { created_after: time }
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

      get api_v1_materials_path, { created_before: time }
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

      get api_v1_materials_path, { created_after: time - 100, created_before: time + 100 }
      expect(response).to be_success
      materials_json = JSON.parse(response.body, symbolize_names: true)

      expect(materials_json[:data].count).to eq(middle_materials.size)

      materials_json[:data].zip(middle_materials).each { |material_json, material|
        expect(material_json[:id]).to eq(material.uuid)
      }
    end
  end
end