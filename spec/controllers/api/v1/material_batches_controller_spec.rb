require 'rails_helper'

RSpec.describe "MaterialBatches", type: :request do
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

      expect { post_json }.to change { Material.count }.by(3)
                                  .and change { MaterialType.count }.by(0)
                                           .and change { Metadatum.count }.by(9)
      expect(response).to be_created

      new_materials = Material.last(3)

      expect(new_materials.size).to eq(material_batch.materials.size)
      new_materials.zip(material_batch.materials).each { |new_material, material|
        expect(new_material.material_type).to eq(material.material_type)
        expect(new_material.metadata.size).to eq(material.metadata.size)
        new_material.metadata.zip(material.metadata).each { |new_metadata, metadata|
          expect(new_metadata.key).to eq(metadata.key)
          expect(new_metadata.value).to eq(metadata.value)
        }
      }

      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json[:data][:relationships][:materials][:data].size).to eq(new_materials.size)
      response_json[:data][:relationships][:materials][:data].zip(new_materials).each { |material_json, material|
        expect(material_json[:id]).to eq(material.uuid)
        expect(response_json[:included].find { |included| included[:type] == "materials" and included[:id] == material.uuid }[:attributes][:name]).to eq(material.name)
      }
    end

    it 'should not save anything to the database if invalid' do
      material_batch = build(:material_batch_with_metadata)
      material_batch.materials.last.name = nil

      @material_batch_json = {
          data: {
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

      expect { post_json }.to change { Material.count }.by(0)
                                  .and change { MaterialType.count }.by(0)
                                           .and change { Metadatum.count }.by(0)
      expect(response).to be_unprocessable
      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json).to include(:'materials.name')
      expect(response_json[:'materials.name']).to include('can\'t be blank')
    end

    it 'should create materials with parents' do
      material_batch = build(:material_batch_with_metadata)
      material_batch.materials.each { |material|
        material.parents << create(:material)
      }

      @material_batch_json = {
          data: {
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
                              parents: {
                                  data: material.parents.map { |parent| {
                                      id: parent.uuid
                                  } }
                              }
                          }
                      } }
                  }
              }
          }
      }

      expect { post_json }.to change { Material.count }.by(3)
                                  .and change { MaterialType.count }.by(0)
                                           .and change { Metadatum.count }.by(0)
      expect(response).to be_created

      new_materials = Material.last(3)

      expect(new_materials.size).to eq(material_batch.materials.size)
      new_materials.zip(material_batch.materials).each { |new_material, material|
        expect(new_material.parents).to eq(material.parents)
      }

      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json[:data][:relationships][:materials][:data].size).to eq(new_materials.size)
      response_json[:data][:relationships][:materials][:data].zip(new_materials).each { |material_json, material|
        expect(material_json[:id]).to eq(material.uuid)
        included_material = response_json[:included].find { |included| included[:type] == "materials" and included[:id] == material.uuid }
        expect(included_material[:attributes][:name]).to eq(material.name)
        expect(included_material[:relationships][:parents][:data].map { |parent_data| parent_data[:id] }).to eq(material.parents.map { |parent| parent.uuid })
      }
    end

    it 'should create a material_batch with existing materials' do
      material_batch = build(:material_batch, materials: create_list(:material, 3))

      @material_batch_json = {
          data: {
              relationships: {
                  materials: {
                      data: material_batch.materials.map { |material| {
                          id: material.uuid
                      } }
                  }
              }
          }
      }

      expect { post_json }.to change { Material.count }.by(0)
                                  .and change { MaterialType.count }.by(0)
                                           .and change { Metadatum.count }.by(0)
      expect(response).to be_created

      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json[:data][:relationships][:materials][:data].size).to eq(material_batch.materials.size)
      response_json[:data][:relationships][:materials][:data].zip(material_batch.materials).each { |material_json, material|
        expect(material_json[:id]).to eq(material.uuid)
        expect(response_json[:included].find { |included| included[:type] == "materials" and included[:id] == material.uuid }[:attributes][:name]).to eq(material.name)
      }
    end

    it 'should create a material_batch with existing materials and edit the materials' do
      material_batch = build(:material_batch, materials: create_list(:material, 3))

      @material_batch_json = {
          data: {
              relationships: {
                  materials: {
                      data: material_batch.materials.map { |material| {
                          id: material.uuid,
                          attributes: {
                              name: "#{material.name}_changed"
                          }
                      }}
                  }
              }
          }
      }

      expect { post_json }.to change { Material.count }.by(0)
                                  .and change { MaterialType.count }.by(0)
                                           .and change { Metadatum.count }.by(0)
      expect(response).to be_created

      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json[:data][:relationships][:materials][:data].size).to eq(material_batch.materials.size)
      response_json[:data][:relationships][:materials][:data].zip(material_batch.materials).each { |material_json, material|
        expect(material_json[:id]).to eq(material.uuid)
        expect(response_json[:included].find { |included| included[:type] == "materials" and included[:id] == material.uuid }[:attributes][:name]).to eq("#{material.name}_changed")

        expect(Material.find(material.id).name).to eq("#{material.name}_changed")
      }
    end
  end
end
