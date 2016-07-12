# See README.md for copyright details

class Api::V1::ApplicationResource < JSONAPI::Resource
  abstract

  attributes :created_at
end