require 'rails_helper'

describe Api::V1::MaterialsController, type: :request do
  def validate_material(material_json_data, material)
    expect(material_json_data[:id]).to eq(material.uuid)
    expect(material_json_data[:attributes][:name]).to eq(material.name)
    expect(material_json_data[:attributes][:'created-at']).to eq(material.created_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ'))
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

    it 'should only return materials of the correct type' do
      create_list(:material, 3)
      material_type = create(:material_type)
      materials = create_list(:material, 3, material_type: material_type)
      create_list(:material, 3)

      get api_v1_materials_path, params: { material_type: material_type.name }
      expect(response).to be_success
      materials_json = JSON.parse(response.body, symbolize_names: true)

      expect(materials_json[:data].count).to eq(materials.size)

      materials_json[:data].zip(materials).each { |material_json, material|
        expect(material_json[:id]).to eq(material.uuid)
      }
    end

    it 'should return empty if given invalid type' do
      create_list(:material, 9)

      get api_v1_materials_path, params: { material_type: "fake_name" }
      expect(response).to be_success
      materials_json = JSON.parse(response.body, symbolize_names: true)

      expect(materials_json[:data].count).to eq(0)
    end

    it 'should return materials of the correct name' do
      create_list(:material, 3)
      material = create(:material)
      create_list(:material, 3)

      get api_v1_materials_path, params: { name: material.name }
      expect(response).to be_success
      materials_json = JSON.parse(response.body, symbolize_names: true)

      expect(materials_json[:data].count).to eq(1)

      expect(materials_json[:data][0][:id]).to eq(material.uuid)
    end

    it 'should return materials made after the given date' do
      time = Time.now

      old_materials = create_list(:material, 3, created_at: time - 100)
      new_materials = create_list(:material, 3, created_at: time + 100)

      get api_v1_materials_path, params: { created_after: time }
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

      get api_v1_materials_path, params: { created_before: time }
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

      get api_v1_materials_path, params: { created_after: time - 100, created_before: time + 100 }
      expect(response).to be_success
      materials_json = JSON.parse(response.body, symbolize_names: true)

      expect(materials_json[:data].count).to eq(middle_materials.size)

      materials_json[:data].zip(middle_materials).each { |material_json, material|
        expect(material_json[:id]).to eq(material.uuid)
      }
    end
  end

  describe "POST #create" do

    let(:post_json) {
      headers = {
          'Content-Type' => 'application/json'
      }

      post api_v1_materials_path, params: @material_json.to_json, headers: headers
    }

    let(:check_response_is_same) {
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

      check_response_is_same
    end

    it "should create a material instance when a UUID is provided" do
      material = build(:material, material_type: create(:material_type))
      material.valid?

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

      check_response_is_same
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

      expect(response_json).to include(:'metadata.key')
      expect(response_json[:'metadata.key']).to include('can\'t be blank')
    end

    it 'should set material parents if given' do
      material = build(:material, parents: create_list(:material, 3))

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
                  parents: {
                      data: material.parents.map { |parent| {
                          id: parent.uuid
                      }}
                  }
              }
          }
      }

      expect { post_json }.to change { Material.count }.by(1)
      expect(response).to be_success

      new_material = Material.last
      expect(new_material.name).to eq(material.name)
      expect(new_material.parents.size).to eq(material.parents.size)
      expect(new_material.parents).to eq(material.parents)

      post_response = response
      get api_v1_material_path(new_material.uuid)
      get_response = response

      expect(post_response.body).to eq(get_response.body)
    end

    it 'should fail when parent uuid does not exist' do
      material = build(:material, parents: build_list(:material, 3))

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
                  parents: {
                      data: material.parents.map { |parent| {
                          id: parent.uuid
                      }}
                  }
              }
          }
      }

      expect { post_json }.to change { Material.count }.by(0)
      expect(response).to be_unprocessable

      response_json = JSON.parse(response.body, symbolize_names: true)
      expect(response_json).to include(:parents)
      expect(response_json[:parents]).to include 'must exist'
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

      expect(response_json).to include(:'metadata.key')
      expect(response_json[:'metadata.key']).to include('can\'t be blank')

      new_material = Material.find(@material.id)

      expect(new_material.name).to eq(@material.name)
      expect(new_material.metadata.size).to eq(@material.metadata.size)
      new_material.metadata.zip(@material.metadata).each { |new_metadatum, metadatum|
        expect(new_metadatum.key).to eq(metadatum.key)
        expect(new_metadatum.value).to eq(metadatum.value)
      }
    end

    it 'should add parents to a material' do
      @material = create(:material)
      parents = create_list(:material, 3)

      @material_json = {
          data: {
              relationships: {
                  parents: {
                      data: parents.map { |parent| {
                          id: parent.uuid
                      }}
                  }
              }
          }
      }

      update_material
      expect(response).to be_success

      put_response = response
      get api_v1_material_path(@material.uuid)
      get_json = response
      expect(put_response.body).to eq(get_json.body)

      new_material = Material.find(@material.id)

      expect(new_material.parents).to eq(parents)
    end

    it 'should append new parents to the existing array' do
      @material = create(:material_with_parents)
      parents = create_list(:material, 3)

      @material_json = {
          data: {
              relationships: {
                  parents: {
                      data: parents.map { |parent| {
                          id: parent.uuid
                      }}
                  }
              }
          }
      }

      update_material
      expect(response).to be_success

      put_response = response
      get api_v1_material_path(@material.uuid)
      get_json = response
      expect(put_response.body).to eq(get_json.body)

      new_material = Material.find(@material.id)

      expect(new_material.parents).to eq(@material.parents + parents)
      new_material.parents.each {|parent|
        expect(parent.children).to eq([@material])
      }
    end

    it 'should keep old parents if none given' do
      @material = create(:material_with_parents)

      @material_json = {
          data: {
              relationships: {
                  parents: {
                      data: []
                  }
              }
          }
      }

      update_material
      expect(response).to be_success

      put_response = response
      get api_v1_material_path(@material.uuid)
      get_json = response
      expect(put_response.body).to eq(get_json.body)

      new_material = Material.find(@material.id)

      expect(new_material.parents).to eq(@material.parents)
    end

    it 'should fail and rollback if parent don\'t exist' do
      @material = create(:material_with_parents)
      parents = build_list(:material, 3)

      @material_json = {
          data: {
              relationships: {
                  parents: {
                      data: parents.map { |parent| {
                          id: parent.uuid
                      }}
                  }
              }
          }
      }

      update_material
      expect(response).to be_unprocessable
      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json).to include(:parents)
      expect(response_json[:parents]).to include('must exist')

      new_material = Material.find(@material.id)
      expect(new_material.parents).to eq(@material.parents)
    end
  end
end