require 'rails_helper'

RSpec.describe "MaterialBatches", type: :request do
  def validate_material_batch(material_batch_json_data, material_batch)
    expect(material_batch_json_data[:id]).to eq(material_batch.id.to_s)
    expect(material_batch_json_data[:attributes][:name]).to eq(material_batch.name)
    expect(material_batch_json_data[:relationships][:materials][:data].size).to eq(material_batch.materials.size)

    material_batch_json_data[:relationships][:materials][:data].zip(material_batch.materials).each do |material_response, material_original|
      expect(material_response[:id]).to eq(material_original.uuid)
    end
  end

  describe "GET #show" do
    it "should return a serialized material_batch instance" do
      material_batch = create(:material_batch_with_metadata)

      get api_v1_material_batch_path(material_batch)
      expect(response).to be_success

      material_batch_json = JSON.parse(response.body, symbolize_names: true)

      validate_material_batch(material_batch_json[:data], material_batch)

      expect(material_batch_json[:included].select { |obj| obj[:type] == "materials" }.size).to eq(material_batch.materials.size)
      expect(material_batch_json[:included].select { |obj| obj[:type] == "material-types" }.size).to eq(material_batch.materials.uniq { |material| material.material_type }.size)
      expect(material_batch_json[:included].select { |obj| obj[:type] == "metadata" }.size).to eq(material_batch.materials.sum { |material| material.metadata.size })
    end
  end

  describe "GET #index" do
    it "should return a list of serialized material_batch instances" do
      material_batches = create_list(:material_batch_with_metadata, 3)

      get api_v1_material_batches_path
      expect(response).to be_success

      material_batches_json = JSON.parse(response.body, symbolize_names: true)

      material_batches_json[:data].zip(material_batches).each { |material_batch_json, material_batch| validate_material_batch(material_batch_json, material_batch) }

      expect(material_batches_json[:included].select { |obj| obj[:type] == "materials" }.size).to eq(material_batches.sum { |mb| mb.materials.size })
      expect(material_batches_json[:included].select { |obj| obj[:type] == "material-types" }.size).to eq(material_batches.sum { |mb| mb.materials.uniq { |material| material.material_type }.size })
      expect(material_batches_json[:included].select { |obj| obj[:type] == "metadata" }.size).to eq(material_batches.sum { |mb| mb.materials.sum { |material| material.metadata.size } })
    end
  end

  describe "POST #create" do
    let(:post_json) {
      headers = {
          'Content-Type' => 'application/json'
      }

      post api_v1_material_batches_path, params: @material_batch_json.to_json, headers: headers
    }

    it "should create a material_batch instance" do
      material_batch = build(:material_batch_with_metadata)

      @material_batch_json = {
          data: {
              attributes: {
                  name: material_batch.name
              },
              relationships: {
                  materials: {
                      data: material_batch.materials.map { |material| {
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
                      } }
                  }
              }
          }
      }

      expect { post_json }.to change { MaterialBatch.count }.by(1)
                          .and change { Material.count }.by(3)
                          .and change { MaterialType.count }.by(0)
                          .and change { Metadatum.count }.by(9)
      expect(response).to be_created

      new_material_batch = MaterialBatch.last

      post_response = response
      get api_v1_material_batch_path(new_material_batch)
      get_response = response
      expect(post_response.body).to eq(get_response.body)

      expect(new_material_batch.name).to eq(material_batch.name)
      expect(new_material_batch.materials.size).to eq(material_batch.materials.size)
    end

    it 'should not save anything to the database if invalid' do
      material_batch = build(:material_batch_with_metadata)
      material_batch.materials.last.name = nil

      @material_batch_json = {
          data: {
              attributes: {
                  name: material_batch.name
              },
              relationships: {
                  materials: {
                      data: material_batch.materials.map { |material| {
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
                      } }
                  }
              }
          }
      }

      expect { post_json }.to change { MaterialBatch.count }.by(0)
                          .and change { Material.count }.by(0)
                          .and change { MaterialType.count }.by(0)
                          .and change { Metadatum.count }.by(0)
      expect(response).to be_unprocessable
      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json).to include(:'material.name')
      expect(response_json[:'material.name']).to include('can\'t be blank')
    end
  end

  describe "PUT #update" do
    let(:update_material_batch) {
      headers = {
          'Content-Type' => 'application/json'
      }

      put api_v1_material_batch_path(@material_batch), params: @material_batch_json.to_json, headers: headers
    }

    it 'should update the material_batch' do
      @material_batch = create(:material_batch_with_metadata)

      @material_batch_json = {
          data: {
              attributes: {
                  name: 'new name'
              }
          }
      }

      expect { update_material_batch }.to change { MaterialBatch.count }.by(0)
                                      .and change { Material.count }.by(0)
                                      .and change { MaterialType.count }.by(0)
                                      .and change { Metadatum.count }.by(0)
      expect(response).to be_success
      expect(MaterialBatch.find(@material_batch.id).name).to eq("new name")

      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json[:data][:attributes][:name]).to eq('new name')
    end

    it "should update the material_batch when changing the materials" do
      @material_batch = create(:material_batch_with_metadata)

      @material_batch_json = {
          data: {
              relationships: {
                  materials: {
                      data: @material_batch.materials.map { |material| {
                          id: material.uuid,
                          attributes: {
                              name: material.name + '_changed'
                          }
                      } }
                  }
              }
          }
      }

      expect { update_material_batch }.to  change { MaterialBatch.count }.by(0)
                                      .and change { Material.count }.by(0)
                                      .and change { MaterialType.count }.by(0)
                                      .and change { Metadatum.count }.by(0)
      expect(response).to be_success
      response_json = JSON.parse(response.body, symbolize_names: true)

      new_material_batch = MaterialBatch.find(@material_batch.id)

      new_material_batch.materials.zip(@material_batch.materials).each { |new_material, old_material|
        expect(new_material.name).to eq(old_material.name + "_changed")
      }
    end

    it "should update the material_batch when adding an existing material" do
      @material_batch = create(:material_batch_with_metadata)
      material = create(:material_with_metadata)

      @material_batch_json = {
          data: {
              relationships: {
                  materials: {
                      data: [
                          id: material.uuid,
                      ]
                  }
              }
          }
      }

      expect { update_material_batch }.to change { MaterialBatch.count }.by(0)
                                      .and change { Material.count }.by(0)
                                      .and change { MaterialType.count }.by(0)
                                      .and change { Metadatum.count }.by(0)
                                      .and change { @material_batch.materials.count }.by(1)
      expect(response).to be_success
      response_json = JSON.parse(response.body, symbolize_names: true)

      new_material_batch = MaterialBatch.find(@material_batch.id)
      expect(new_material_batch.materials).to include(material)

      (@material_batch.materials + [material]).zip(new_material_batch.materials).each { |old_material, persisted_material|
        expect(old_material.name).to eq(persisted_material.name)
      }
    end

    it "should update the material_batch when adding a new material" do
      @material_batch = create(:material_batch_with_metadata)
      material = build(:material_with_metadata, material_type: create(:material_type))

      @material_batch_json = {
          data: {
              relationships: {
                  materials: {
                      data: [
                          {
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
                                      data: material.metadata.map{ |metadatum| {
                                          attributes: {
                                            key: metadatum.key,
                                            value: metadatum.value
                                          }
                                      }}
                                  }
                              }
                          }
                      ]
                  }
              }
          }
      }

      expect { update_material_batch }.to change { MaterialBatch.count }.by(0)
                                      .and change { Material.count }.by(1)
                                      .and change { MaterialType.count }.by(0)
                                      .and change { Metadatum.count }.by(3)
                                      .and change { @material_batch.materials.count }.by(1)
      expect(response).to be_success
      response_json = JSON.parse(response.body, symbolize_names: true)

      new_material_batch = MaterialBatch.find(@material_batch.id)

      (@material_batch.materials + [material]).zip(new_material_batch.materials).each { |old_material, persisted_material|
        expect(old_material.name).to eq(persisted_material.name)

        old_material.metadata.zip(persisted_material.metadata).each { |old_metadatum, persisted_metadatum|
          expect(old_metadatum.key).to eq(persisted_metadatum.key)
          expect(old_metadatum.value).to eq(persisted_metadatum.value)
        }
      }
    end

    it 'should rollback completely if invalid' do
      @material_batch = create(:material_batch_with_metadata)

      @material_batch_json = {
          data: {
              attributes: {
                  name: 'new_batch_name'
              },
              relationships: {
                  materials: {
                      data: [
                          {
                              id: @material_batch.materials.first.uuid,
                              attributes: {
                                  name: 'new_material_name'
                              }
                          },
                          {
                              id: @material_batch.materials.first.uuid,
                              attributes: {
                                  name: ''
                              }
                          }
                      ]
                  }
              }
          }
      }

      expect { update_material_batch }.to change { MaterialBatch.count }.by(0)
                                      .and change { Material.count }.by(0)
                                      .and change { MaterialType.count }.by(0)
                                      .and change { Metadatum.count }.by(0)
      expect(response).to be_unprocessable
      response_json = JSON.parse(response.body, symbolize_names: true)

      new_material_batch = MaterialBatch.find(@material_batch.id)

      expect(new_material_batch.name).to eq(@material_batch.name)
      (@material_batch.materials).zip(new_material_batch.materials).each { |old_material, persisted_material|
        expect(old_material.name).to eq(persisted_material.name)
      }

      expect(response_json).to include(:'material.name')
      expect(response_json[:'material.name']).to include('can\'t be blank')
    end

  end
end
