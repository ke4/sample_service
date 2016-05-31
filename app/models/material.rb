# See README.md for copyright details
require 'uuid'

class Material < ApplicationRecord
  belongs_to :material_type
  has_many :metadata, inverse_of: :material

  has_many :parent_derivatives, class_name: 'MaterialDerivative', foreign_key: 'child_id', inverse_of: :child
  has_many :parents, through: :parent_derivatives

  has_many :child_derivatives, class_name: 'MaterialDerivative', foreign_key: 'parent_id', inverse_of: :parent
  has_many :children, through: :child_derivatives

  validates :name, presence: true
  validates :uuid, uuid: true, unless: 'uuid.nil?'

  after_validation :generate_uuid, if: "uuid.nil?"

  attr_accessor :expected_parent_uuids
  validate :expected_parents_match, if: :expected_parent_uuids

  # accepts_nested_attributes_for :metadata
  attr_accessor :metadata_attributes
  validate :metadata_check

  def self.my_new(params)
    object = Material.new(params)

    object.metadata = (params[:metadata_attributes] or []).map { |attr| Metadatum.new(attr) }

    object
  end

  def my_assign_attributes(params)
    self.assign_attributes(params)

    new_metadata = []
    (params[:metadata_attributes] or []).each { |attr|
      if attr.has_key? :id
        metadata.find { |m| m.id.to_s == attr[:id].to_s }.assign_attributes(attr)
      else
        new_metadata << attr
      end
    }
    self.metadata.build(new_metadata)

    valid?
  end

  def my_update(params)
    return false unless my_assign_attributes(params)

    ActiveRecord::Base.transaction do
      self.save!
      self.metadata.each { |md| md.save! }
    end

    true
  end

  private

  def generate_uuid
    self.uuid = UUID.new.generate
  end

  def expected_parents_match
    errors.add :parents, I18n.t('errors.messages.doesnt_exist') unless expected_parent_uuids == parents.map { |parent| parent.uuid }
  end

  def metadata_check
    self.metadata.each { |metadatum|
      metadatum.valid?
      metadatum.errors.each { |key|
        metadatum.errors[key].each { |error|
          self.errors.add "metadata.#{key}", error
        }
      }
    }
  end
end
