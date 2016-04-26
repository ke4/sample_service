# See README.md for copyright details
require 'uuid'

class Material < ApplicationRecord
  belongs_to              :material_type
  has_and_belongs_to_many :material_batch
  has_many                :metadata
  has_and_belongs_to_many :children, class_name: 'Material', join_table: 'material_derivatives', foreign_key: :parent_id, association_foreign_key: :child_id
  has_and_belongs_to_many :parents,  class_name: 'Material', join_table: 'material_derivatives', foreign_key: :child_id,  association_foreign_key: :parent_id

  validates :name, presence: true
  validates :uuid, uniqueness: {case_sensitive: false}, uuid: true
  validates :metadata, gather_attribute_errors: true

  after_initialize :generate_uuid, if: "uuid.nil?"

  attr_accessor :expected_parent_uuids
  validate :expected_parents_match, if: :expected_parent_uuids

  def self.build_from_params(params)
    material_type = MaterialType.find_by(material_type_create_params(params))
    metadata = metadata_create_params(params)[:metadata].nil? ? [] : metadata_create_params(params)[:metadata][:data].map { |metadatum| Metadatum.new(metadatum[:attributes]) }

    parent_uuids = parents_create_params(params)[:parents].nil? ? [] : parents_create_params(params)[:parents][:data].map { |parent_param| parent_param[:id] }
    parents = Material.where(uuid: parent_uuids)

    material_params = material_create_params(params)
    material_params[:uuid] = material_params.delete :id

    Material.new(material_params.merge(material_type: material_type, metadata: metadata, parents: parents, expected_parent_uuids: parent_uuids))
  end

  def update_from_params(params)
    ActiveRecord::Base.transaction do
      material_type = self.material_type
      parents = self.parents
      parent_uuids = parents.map { |parent| parent.uuid }

      if metadata_update_params(params)[:relationships] and material_type_update_params(params)[:relationships][:material_type]
        material_type = MaterialType.find_by(material_type_update_params(params)[:relationships][:material_type][:data][:attributes])
      end

      if metadata_update_params(params)[:relationships] and metadata_update_params(params)[:relationships][:metadata]
        metadata_update_params(params)[:relationships][:metadata][:data].each do |new_metadatum|
          metadatum = self.metadata.find { |metadatum| metadatum.key == new_metadatum[:attributes][:key] }
          if metadatum.nil?
            self.metadata << Metadatum.new(new_metadatum[:attributes])
          else
            metadatum.value = new_metadatum[:attributes][:value]
          end
        end
      end

      if parents_update_params(params)[:relationships] and parents_update_params(params)[:relationships][:parents]
        parent_uuids += parents_update_params(params)[:relationships][:parents][:data].map { |parent| parent[:id] }
        parents = Material.where(uuid: parent_uuids)
      end

      material_params = material_update_params(params)
      if material_params[:id]
        material_params[:uuid] = material_params.delete :id
      end
      self.update((material_params or {}).merge(material_type: material_type, parents: parents, expected_parent_uuids: parent_uuids))
      self.metadata.each { |metadatum|
        metadatum.save
        metadatum.errors.each { |key|
          metadatum.errors[key].each { |error|
            self.errors.add("metadatum.#{key}", error)
          }
        }
      }

      if errors.empty?
        return true
      else
        raise ActiveRecord::Rollback
      end
    end

    false
  end

  private

  def generate_uuid
    self.uuid = UUID.new.generate
  end

  def self.material_create_params(params)
    params.permit([:id, attributes: [:name]])
  end

  def self.material_type_create_params(params)
    params.require(:relationships).require(:material_type).require(:data).require(:attributes).permit(:name)
  end

  def self.metadata_create_params(params)
    params.require(:relationships).permit(metadata: {data: [attributes: [:key, :value]]})
  end

  def self.parents_create_params(params)
    params.require(:relationships).permit(parents: { data: [:id] })
  end

  def material_update_params(params)
    params.permit([:id, attributes: [:name]])
  end

  def material_type_update_params(params)
    params.permit(relationships: {material_type: {data: {attributes: [:name]}}})
  end

  def metadata_update_params(params)
    params.permit(relationships: {metadata: {data: [attributes: [:key, :value]]}})
  end

  def parents_update_params(params)
    params.permit(relationships: {parents: {data: [:id]}})
  end

  def expected_parents_match
    errors.add :parents, 'must exist' unless expected_parent_uuids == parents.map { |parent| parent.uuid }
  end
end
