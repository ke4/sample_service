require 'rails_helper'

describe Api::V1::MaterialsController, type: :request do
  def validate_material(material_json_data, material)
    expect(material_json_data[:id]).to eq(material.uuid)
    expect(material_json_data[:attributes][:name]).to eq(material.name)
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

      get api_v1_material_path(material.uuid)
      expect(response).to be_success

      material_json = JSON.parse(response.body, symbolize_names: true)

      validate_material(material_json[:data], material)

      material_type_json = material_json[:included].select { |obj| obj[:type] == 'material-types' }[0]

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

    let(:post_json) {
      headers = {
          'Content-Type' => 'application/json'
      }

      post api_v1_materials_path, params: @material_json.to_json, headers: headers
    }

    let(:check_reponse_is_same) {
      expect(response).to be_created
      post_response = response
      get api_v1_material_path(Material.last.uuid)
      get_response = response
      expect(post_response.body).to eq(get_response.body)
    }

    it "should create a material instance" do
      material = build(:material, material_type: create(:material_type))

      @material_json = {
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
      }

      expect { post_json }.to  change { Material.count }.by(1)
                          .and change { MaterialType.count }.by(0)
                          .and change { Metadatum.count }.by(0)

      new_material = Material.last
      expect(new_material.name).to eq(material.name)
      expect(new_material.material_type).to eq(material.material_type)
      expect(new_material.uuid.length).to eq(36)
      expect(new_material.metadata).to be_empty

      check_reponse_is_same
    end

    it "should create a material instance when a UUID is provided" do
      material = build(:material, material_type: create(:material_type))

      @material_json = {
          data: {
              id: material.uuid,
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
      }

      expect { post_json }.to  change { Material.count }.by(1)
                          .and change { MaterialType.count }.by(0)
                          .and change { Metadatum.count }.by(0)

      new_material = Material.last
      expect(new_material.uuid).to eq(material.uuid)

      check_reponse_is_same
    end

    it 'should return an error if posting an invalid uuid' do
      material = build(:material, material_type: create(:material_type))

      @material_json = {
          data: {
              id: '123456789',
              attributes: {
                  name: material.name,
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
      }

      post_json
      expect(response).to be_unprocessable
      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json).to include(:uuid)
      expect(response_json[:uuid]).to include('is not a valid UUID')
    end

    it 'should return the created instance' do
      material = build(:material, material_type: create(:material_type))

      @material_json = {
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
      }

      post_json
      expect(response).to be_created
      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json[:data][:id]).to eq(Material.last.uuid)
      expect(response_json[:data][:type]).to eq('materials')
      expect(response_json[:data][:attributes][:name]).to eq(material.name)
      expect(response_json[:data][:relationships][:"material-type"][:data][:id]).to eq(material.material_type.id.to_s)

      expect(response_json[:included].find { |obj| obj[:type] == 'material-types' }[:id]).to eq(material.material_type.id.to_s)
      expect(response_json[:included].find { |obj| obj[:type] == 'material-types' }[:attributes][:name]).to eq(material.material_type.name)
    end

    it "should create a material instance with metadata" do
      material = build(:material_with_metadata, material_type: create(:material_type))

      @material_json = {
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
                      data: material.metadata.map { |metadatum| {attributes: {key: metadatum.key, value: metadatum.value}} }
                  }
              }
          }
      }

      expect { post_json }.to  change { Material.count }.by(1)
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

      @material_json = {
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
                      data: material.metadata.map { |metadatum| {attributes: {key: metadatum.key, value: metadatum.value}} }
                  }
              }
          }
      }

      post_json
      expect(response).to be_created
      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json[:data][:relationships][:metadata][:data].size).to eq(material.metadata.size)

      expect(response_json[:included].select { |obj| obj[:type] == 'metadata' }.size).to eq(material.metadata.size)
      response_json[:included].select { |obj| obj[:type] == 'metadata' }.zip(material.metadata).each do |included_metadata, metadata|
        expect(included_metadata[:attributes][:key]).to eq(metadata.key)
        expect(included_metadata[:attributes][:value]).to eq(metadata.value)
      end
    end

    it "should fail if the material type does not exists" do
      material = build(:material)

      @material_json = {
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
      }

      expect { post_json }.to  change { Material.count }.by(0)
                          .and change { MaterialType.count }.by(0)
                          .and change { Metadatum.count }.by(0)
      expect(response).to be_unprocessable
      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json).to include(:material_type)
      expect(response_json[:material_type]).to include('must exist')
    end

    it 'should fail if given invalid metadata' do
      material = build(:material_with_metadata, material_type: create(:material_type))
      material.metadata.last.key = ''

      @material_json = {
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
                      data: material.metadata.map { |metadatum| {
                          attributes: {
                              key: metadatum.key,
                              value: metadatum.value
                          }
                      } }
                  }
              }
          }
      }

      expect { post_json }.to  change { Material.count }.by(0)
                          .and change { MaterialType.count }.by(0)
                          .and change { Metadatum.count }.by(0)
      expect(response).to be_unprocessable
      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json).to include(:'metadatum.key')
      expect(response_json[:'metadatum.key']).to include('can\'t be blank')
    end
  end

  describe "PUT #update" do
    let(:update_material) {
      headers = {
          'Content-Type' => 'application/json'
      }

      put api_v1_material_path(@material.uuid), params: @material_json.to_json, headers: headers
    }

    it 'should update the attributes' do
      @material = create(:material)
      new_name = 'new name'

      @material_json = {
          data: {
              attributes: {
                  name: new_name
              }
          }
      }

      expect { update_material }.to  change { Material.count }.by(0)
                                .and change { MaterialType.count }.by(0)
                                .and change { Metadatum.count }.by(0)

      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to be_success

      expect(response_json[:data][:attributes][:name]).to eq(new_name)

      new_material = Material.find(@material.id)

      expect(new_material.name).to eq(new_name)
      expect(new_material.uuid).to eq(@material.uuid)
    end

    it 'should keep the old attributes if none are provided' do
      @material = create(:material)
      old_name = @material.name
      new_uuid = UUID.new.generate

      @material_json = {
          data: {
              id: new_uuid
          }
      }

      expect { update_material }.to  change { Material.count }.by(0)
                                .and change { MaterialType.count }.by(0)
                                .and change { Metadatum.count }.by(0)

      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to be_success

      expect(response_json[:data][:id]).to eq(new_uuid)
      expect(response_json[:data][:attributes][:name]).to eq(old_name)

      @material.reload

      expect(@material.name).to eq(old_name)
      expect(@material.uuid).to eq(new_uuid)
    end

    it 'should update the material_type' do
      @material = create(:material)
      new_material_type = create(:material_type)
      new_name = 'new name'
      new_uuid = UUID.new.generate

      @material_json = {
          data: {
              id: new_uuid,
              attributes: {
                  name: new_name,
              },
              relationships: {
                  material_type: {
                      data: {
                          attributes: {
                              name: new_material_type.name
                          }
                      }
                  }
              }
          }
      }

      expect { update_material }.to  change { Material.count }.by(0)
                                .and change { MaterialType.count }.by(0)
                                .and change { Metadatum.count }.by(0)

      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to be_success

      expect(response_json[:data][:id]).to eq(new_uuid)
      expect(response_json[:data][:attributes][:name]).to eq(new_name)
      expect(response_json[:data][:relationships][:"material-type"][:data][:id]).to eq(new_material_type.id.to_s)

      @material.reload

      expect(@material.name).to eq(new_name)
      expect(@material.uuid).to eq(new_uuid)
      expect(@material.material_type).to eq(new_material_type)
    end

    it 'should update the material_type without updating attributes' do
      @material = create(:material)
      original_name = @material.name
      original_uuid = @material.uuid

      new_material_type = create(:material_type)

      @material_json = {
          data: {
              relationships: {
                  material_type: {
                      data: {
                          attributes: {
                              name: new_material_type.name
                          }
                      }
                  }
              }
          }
      }

      expect { update_material }.to  change { Material.count }.by(0)
                                .and change { MaterialType.count }.by(0)
                                .and change { Metadatum.count }.by(0)

      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to be_success

      expect(response_json[:data][:id]).to eq(original_uuid)
      expect(response_json[:data][:attributes][:name]).to eq(original_name)
      expect(response_json[:data][:relationships][:"material-type"][:data][:id]).to eq(new_material_type.id.to_s)

      @material.reload

      expect(@material.name).to eq(original_name)
      expect(@material.uuid).to eq(original_uuid)
      expect(@material.material_type).to eq(new_material_type)
    end

    it 'should update the existing metadata' do
      @material = create(:material_with_metadata)

      @material_json = {
          data: {
              attributes: {
                  name: @material.name
              },
              relationships: {
                  material_type: {
                      data: {
                          attributes: {
                              name: @material.material_type.name
                          }
                      }
                  },
                  metadata: {
                      data: @material.metadata.map { |metadatum| {attributes: {key: metadatum.key, value: metadatum.value + "_changed"}} }
                  }
              }
          }
      }

      expect { update_material }.to  change { Material.count }.by(0)
                                .and change { MaterialType.count }.by(0)
                                .and change { Metadatum.count }.by(0)

      expect(response).to be_success
      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json[:data][:relationships][:metadata][:data].size).to eq(@material.metadata.size)
      response_json[:data][:relationships][:metadata][:data].zip(@material.metadata) do |new_metadata, old_metadata|
        expect(new_metadata[:id]).to eq(old_metadata.id.to_s)
      end
      expect(response_json[:included].select { |obj| obj[:type] == "metadata" }.size).to eq(@material.metadata.size)
      @material.metadata.each do |metadatum|
        metadatum_json = response_json[:included].find { |obj| obj[:type] == "metadata" and obj[:id] == metadatum.id.to_s }
        expect(metadatum_json[:attributes][:key]).to eq(metadatum.key)
        expect(metadatum_json[:attributes][:value]).to eq(metadatum.value + '_changed')
      end

      new_material = Material.find(@material.id)
      new_material.metadata.zip(@material.metadata).each do |new_metadata, old_metadata|
        expect(new_metadata.id).to eq(old_metadata.id)
        expect(new_metadata.key).to eq(old_metadata.key)
        expect(new_metadata.value).to eq(old_metadata.value + '_changed')
      end
    end

    it 'should add additional metadata' do
      @material = create(:material_with_metadata)
      new_metadatum = build(:metadatum)

      @material_json = {
          data: {
              relationships: {
                  metadata: {
                      data: (@material.metadata + [new_metadatum]).map { |metadatum| {attributes: {key: metadatum.key, value: metadatum.value}} }
                  }
              }
          }
      }

      expect { update_material }.to  change { Material.count }.by(0)
                                .and change { MaterialType.count }.by(0)
                                .and change { Metadatum.count }.by(1)
      expect(response).to be_success
      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json[:data][:relationships][:metadata][:data].size).to eq(@material.metadata.size + 1)
      response_json[:data][:relationships][:metadata][:data][0...@material.metadata.size].zip(@material.metadata) do |new_metadata, old_metadata|
        expect(new_metadata[:id]).to eq(old_metadata.id.to_s)
      end

      expect(response_json[:included].select { |obj| obj[:type] == "metadata" }.size).to eq(@material.metadata.size + 1)
      (@material.metadata).each do |metadatum|
        metadatum_json = response_json[:included].find { |obj| obj[:type] == "metadata" and obj[:id] == metadatum.id.to_s }
        expect(metadatum_json[:attributes][:key]).to eq(metadatum.key)
        expect(metadatum_json[:attributes][:value]).to eq(metadatum.value)
      end
      new_metadatum_json = response_json[:included].last
      expect(new_metadatum_json[:attributes][:key]).to eq(new_metadatum.key)
      expect(new_metadatum_json[:attributes][:value]).to eq(new_metadatum.value)

      new_material = Material.find(@material.id)
      new_material.metadata[0...@material.metadata.size].zip(@material.metadata).each do |new_metadata, old_metadata|
        expect(new_metadata.id).to eq(old_metadata.id)
        expect(new_metadata.key).to eq(old_metadata.key)
        expect(new_metadata.value).to eq(old_metadata.value)
      end

      expect(Metadatum.last.key).to eq(new_metadatum.key)
      expect(Metadatum.last.value).to eq(new_metadatum.value)
    end

    it 'should keep all old metadata if none are provided' do
      @material = create(:material_with_metadata)

      @material_json = {
          data: {
              attributes: {},
              relationships: {}
          }
      }

      expect { update_material }.to  change { Material.count }.by(0)
                                .and change { MaterialType.count }.by(0)
                                .and change { Metadatum.count }.by(0)
      expect(response).to be_success
      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json[:data][:relationships][:metadata][:data].size).to eq(@material.metadata.size)
      expect(Material.find(@material.id).metadata).to eq(@material.metadata)
    end

    it 'should not alter the database if the request is unsuccessful' do
      @material = create(:material_with_metadata)
      new_metadatum = build(:metadatum)

      @material_json = {
          data: {
              attributes: {
                  name: "new name"
              },
              relationships: {
                  material_type: {
                      data: {
                          attributes: {
                              name: 'fake material type'
                          }
                      }
                  },
                  metadata: {
                      data: (@material.metadata + [new_metadatum]).map { |metadatum| {attributes: {key: metadatum.key, value: metadatum.value + "_changed"}} }
                  }
              }
          }
      }

      expect { update_material }.to  change { Material.count }.by(0)
                                .and change { MaterialType.count }.by(0)
                                .and change { Metadatum.count }.by(0)
      expect(response).to be_unprocessable
      response_json = JSON.parse(response.body, symbolize_names: true)

      new_material = Material.find(@material.id)
      expect(new_material.name).to eq(@material.name)
      expect(new_material.uuid).to eq(@material.uuid)

      expect(new_material.metadata.first.value).to eq(@material.metadata.first.value)

      expect(response_json).to include(:material_type)
      expect(response_json[:material_type]).to include('must exist')
    end

    it 'should fail if metadata is invalid' do
      @material = create(:material_with_metadata)

      @material_json = {
          data: {
              attributes: {
                  name: @material.name + '_changed'
              },
              relationships: {
                  material_type: {
                      data: {
                          attributes: {
                              name: @material.material_type.name
                          }
                      }
                  },
                  metadata: {
                      data: @material.metadata.map { |metadatum| {
                          attributes: {
                              key: metadatum.key,
                              value: metadatum.value + '_changed'
                          }
                      } } + [{
                                 attributes: {
                                     key: '',
                                     value: 'test value'
                                 }
                             }]
                  }
              }
          }
      }

      expect { update_material }.to  change { Material.count }.by(0)
                                .and change { MaterialType.count }.by(0)
                                .and change { Metadatum.count }.by(0)
      expect(response).to be_unprocessable
      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json).to include(:'metadatum.key')
      expect(response_json[:'metadatum.key']).to include('can\'t be blank')

      new_material = Material.find(@material.id)

      expect(new_material.name).to eq(@material.name)
      expect(new_material.metadata.size).to eq(@material.metadata.size)
      new_material.metadata.zip(@material.metadata).each { |new_metadatum, metadatum|
        expect(new_metadatum.key).to eq(metadatum.key)
        expect(new_metadatum.value).to eq(metadatum.value)
      }
    end
  end
end