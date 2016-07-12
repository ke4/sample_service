# See README.md for copyright details

class Api::V1::MaterialTypeResource < Api::V1::ApplicationResource
  immutable

  attributes :name
end