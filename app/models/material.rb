# See README.md for copyright details
require 'uuid'

class Material < ApplicationRecord
  belongs_to :material_type
  has_many :material_batches_materials
  has_many :material_batches, through: :material_batches_materials
  has_many :metadata, inverse_of: :material
  has_and_belongs_to_many :children, class_name: 'Material', join_table: 'material_derivatives', foreign_key: :parent_id, association_foreign_key: :child_id
  has_and_belongs_to_many :parents, class_name: 'Material', join_table: 'material_derivatives', foreign_key: :child_id, association_foreign_key: :parent_id

  validates :name, presence: true
  validates :uuid, uniqueness: {case_sensitive: false}, uuid: true

  after_initialize :generate_uuid, if: "uuid.nil?"

  attr_accessor :expected_parent_uuids
  validate :expected_parents_match, if: :expected_parent_uuids

  accepts_nested_attributes_for :metadata

  def self.material_params(material, material_json_params)
    params = (material_json_params[:attributes] or {}).merge(uuid: material_json_params[:id]).delete_if { |k, v| v.nil? }

    material_type = material ? material.material_type : nil
    if material_json_params and
        material_json_params[:relationships] and
        material_json_params[:relationships][:material_type] and
        material_json_params[:relationships][:material_type][:data] and
        material_json_params[:relationships][:material_type][:data][:attributes]
      material_type = MaterialType.find_by(material_json_params[:relationships][:material_type][:data][:attributes])
    end

    metadata = material ? material.metadata.map { |metadatum| {id: metadatum.id, key: metadatum.key, value: metadatum.value} } : []
    if material_json_params and
        material_json_params[:relationships] and
        material_json_params[:relationships][:metadata] and
        material_json_params[:relationships][:metadata][:data]

      material_json_params[:relationships][:metadata][:data].each { |metadatum|
        metadatum = metadatum[:attributes]
        existing_metadatum = metadata.find { |m| m[:key] == metadatum[:key] }
        if existing_metadatum
          existing_metadatum[:value] = metadatum[:value]
        else
          metadata << {key: metadatum[:key], value: metadatum[:value]}
        end
      }
    end

    parent_uuids = material ? material.parents.map { |parent| parent.uuid } : []
    if material_json_params and
        material_json_params[:relationships] and
        material_json_params[:relationships][:parents] and
        material_json_params[:relationships][:parents][:data]
      parent_uuids += material_json_params[:relationships][:parents][:data].map { |parent| parent[:id] }
    end

    params.merge(material_type: material_type, metadata_attributes: metadata, parents: Material.where(uuid: parent_uuids), expected_parent_uuids: parent_uuids)
  end
  
  def self.json_schema
    {
        data: [
            :id,
            attributes: [
                :name
            ],
            relationships: {
                material_type: {
                    data: {
                        attributes: [
                            :name
                        ]
                    }
                },
                metadata: {
                    data: [
                        attributes: [
                            :key,
                            :value
                        ]
                    ]
                },
                parents: {
                    data: [
                        :id
                    ]
                }
            }
        ]
    }
  end

  private

  def generate_uuid
    self.uuid = UUID.new.generate
  end

  def expected_parents_match
    errors.add :parents, I18n.t('errors.messages.doesnt_exist') unless expected_parent_uuids == parents.map { |parent| parent.uuid }
  end
end
