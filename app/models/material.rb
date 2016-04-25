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

  def self.build_from_params(params)
    material_type = MaterialType.find_by(material_type_create_params(params))
    metadata = metadata_create_params(params)[:metadata].nil? ? [] : metadata_create_params(params)[:metadata][:data].map { |metadatum| Metadatum.new(metadatum[:attributes]) }

    material_params = material_create_params(params)
    material_params[:uuid] = material_params.delete :id
    Material.new(material_params.merge(material_type: material_type, metadata: metadata))
  end

  def update_from_params(params)
    ActiveRecord::Base.transaction do
      material_type = self.material_type
      unless material_type_update_params(params)[:relationships].nil? or material_type_update_params(params)[:relationships][:material_type].nil?
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

      material_params = material_update_params(params)
      if material_params[:id]
        material_params[:uuid] = material_params.delete :id
      end
      self.update((material_params or {}).merge(material_type: material_type))
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

  def material_update_params(params)
    params.permit([:id, attributes: [:name]])
  end

  def material_type_update_params(params)
    params.permit(relationships: {material_type: {data: {attributes: [:name]}}})
  end

  def metadata_update_params(params)
    params.permit(relationships: {metadata: {data: [attributes: [:key, :value]]}})
  end
end
