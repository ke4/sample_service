# See README.md for copyright details

class Api::V1::MaterialResource < Api::V1::ApplicationResource
  attribute :id, format: :default
  attributes :name, :uuid

  relationship :material_type, to: :one

  key_type :uuid
  primary_key :uuid

  def id
    @model.uuid
  end

end
