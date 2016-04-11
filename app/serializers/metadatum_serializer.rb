# See README.md for copyright details

class MetadatumSerializer < ActiveModel::Serializer
  attributes :id, :key, :value
end
