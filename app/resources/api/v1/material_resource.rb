# See README.md for copyright details

class Api::V1::MaterialResource < Api::V1::ApplicationResource
  attribute :id, format: :default
  attributes :name, :uuid

  has_one :material_type, to: :one
  has_many :metadata, to: :many

  key_type :uuid
  primary_key :uuid

  def id
    @model.uuid
  end

end
