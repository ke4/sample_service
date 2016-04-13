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

      get api_v1_material_path(material)
      expect(response).to be_success

      material_json = JSON.parse(response.body, symbolize_names: true)

      validate_material(material_json[:data], material)

      material_type_json = material_json[:included].select { |obj| obj[:type] == 'material-types' }[0]

      validate_included_material_type(material_type_json, material.material_type)
    end

    it "should return a serialized material instance with metadata" do
      material = create(:material_with_metadata)

      get api_v1_material_path(material)
      expect(response).to be_success

      material_json = JSON.parse(response.body, symbolize_names: true)

      validate_material(material_json[:data], material)

      validate_material_with_metadata(material_json[:data], material)
      validate_included_metadata(material_json[:included].select { |obj| obj[:type] == 'metadata' }, material.metadata)
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
  end

  describe "POST #create" do
    it "should create a material instance" do
      material = build(:material, material_type: create(:material_type))

      material_json = {
        data: {
          attributes: {
            name: material.name
          },
          relationships: {
            material_type: {
              data: {
                attributes: {
                  name: material.material_type.name
                }
              }
            }
          }
        }
      }.to_json
      headers = {
        'Content-Type' => 'application/json'
      }

      expect { post api_v1_materials_path, params: material_json, headers: headers }.to  change { Material.count }.by(1)
                                                                                    .and change { MaterialType.count }.by(0)
                                                                                    .and change { Metadatum.count }.by(0)

      new_material = Material.last
      expect(new_material.name).to eq(material.name)
      expect(new_material.material_type).to eq(material.material_type)
      expect(new_material.uuid.length).to eq(36)
      expect(new_material.metadata).to be_empty
    end

    it 'should return the created instance' do
      material = build(:material, material_type: create(:material_type))

      material_json = {
        data: {
          attributes: {
            name: material.name
          },
          relationships: {
            material_type: {
              data: {
                attributes: {
                  name: material.material_type.name
                }
              }
            }
          }
        }
      }.to_json
      headers = {
        'Content-Type' => 'application/json'
      }

      post api_v1_materials_path, params: material_json, headers: headers
      expect(response).to be_created
      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json[:data][:id]).to eq(Material.last.id.to_s)
      expect(response_json[:data][:type]).to eq('materials')
      expect(response_json[:data][:attributes][:name]).to eq(material.name)
      expect(response_json[:data][:attributes][:uuid]).to eq(Material.last.uuid)
      expect(response_json[:data][:relationships][:"material-type"][:data][:id]).to eq(material.material_type.id.to_s)

      expect(response_json[:included].find{ |obj| obj[:type] == 'material-types' }[:id]).to eq(material.material_type.id.to_s)
      expect(response_json[:included].find{ |obj| obj[:type] == 'material-types' }[:attributes][:name]).to eq(material.material_type.name)
    end

    it "should create a material instance with metadata" do
      material = build(:material_with_metadata, material_type: create(:material_type))

      material_json = {
        data: {
          attributes: {
            name: material.name
          },
          relationships: {
            material_type: {
              data: {
                attributes: {
                  name: material.material_type.name
                }
              }
            },
            metadata: {
              data: material.metadata.map { |metadatum| { attributes: { key: metadatum.key, value: metadatum.value } } }
            }
          }
        }
      }.to_json
      headers = {
        'Content-Type' => 'application/json'
      }

      expect { post api_v1_materials_path, params: material_json, headers: headers }.to  change { Material.count }.by(1)
                                                                                    .and change { MaterialType.count }.by(0)
                                                                                    .and change { Metadatum.count }.by(3)
      expect(response).to be_created

      new_material = Material.last
      expect(new_material.metadata.size).to eq(material.metadata.size)
      new_material.metadata.zip(material.metadata).each do |new_metadata, metadata|
        expect(new_metadata.key).to eq(metadata.key)
        expect(new_metadata.value).to eq(metadata.value)
      end
    end

    it 'should return the created instance' do
      material = build(:material_with_metadata, material_type: create(:material_type))

      material_json = {
        data: {
          attributes: {
            name: material.name
          },
          relationships: {
            material_type: {
              data: {
                attributes: {
                  name: material.material_type.name
                }
              }
            },
            metadata: {
              data: material.metadata.map { |metadatum| { attributes: { key: metadatum.key, value: metadatum.value } } }
            }
          }
        }
      }.to_json
      headers = {
        'Content-Type' => 'application/json'
      }

      post api_v1_materials_path, params: material_json, headers: headers
      expect(response).to be_created
      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json[:data][:relationships][:metadata][:data].size).to eq(material.metadata.size)

      expect(response_json[:included].select{ |obj| obj[:type] == 'metadata' }.size).to eq(material.metadata.size)
      response_json[:included].select{ |obj| obj[:type] == 'metadata' }.zip(material.metadata).each do |included_metadata, metadata|
        expect(included_metadata[:attributes][:key]).to eq(metadata.key)
        expect(included_metadata[:attributes][:value]).to eq(metadata.value)
      end
    end

    it "should fail if the material type does not exists" do
      material = build(:material)

      material_json = {
        data: {
          attributes: {
            name: material.name
          },
          relationships: {
            material_type: {
              data: {
                attributes: {
                  name: "fake material"
                }
              }
            }
          }
        }
      }.to_json
      headers = {
        'Content-Type' => 'application/json'
      }

      expect { post api_v1_materials_path, params: material_json, headers: headers }.to  change { Material.count }.by(0)
                                                                                    .and change { MaterialType.count }.by(0)
                                                                                    .and change { Metadatum.count }.by(0)
      expect(response).to be_unprocessable
      response_json = JSON.parse(response.body, symbolize_names: true)
       
      expect(response_json).to include(:material_type)
      expect(response_json[:material_type]).to include('must exist')
    end
  end

end