class Api::V1::MaterialResource < Api::V1::ApplicationResource

  attributes :id, :name, :material_type, :metadata

  key_type :uuid
  primary_key :uuid

  def id
    @model.uuid
  end

  def id=(id)
    @model.uuid = id
  end

  def material_type
    @model.material_type.name
  end

  def material_type=(name)
    @model.material_type = MaterialType.find_by(name: name)
  end

  def metadata
    @model.metadata.map { |md|
      {key: md.key, value: md.value, created_at: md.created_at}
    }
  end

  def metadata=(metadata)
    metadata.each { |metadatum|
      if (existing_metadata = @model.metadata.find { |md| md.key == metadatum[:key] })
        existing_metadata.update(metadatum)
      else
        @model.metadata << Metadatum.new(metadatum)
      end
    }
  end

  relationship :parents, to: :many
  relationship :children, to: :many

  attributes :parents, :children

  def parents
    @model.parents.map { |parent| {id: parent.uuid, type: "materials"} }
  end

  def parents=(parents)
    @model.parents += Material.where(uuid: parents.map { |parent| parent[:id] })
  end

  def children
    @model.children.map { |child| {id: child.uuid, type: "materials"} }
  end

  def children=(children)
    @model.children += Material.where(uuid: children.map { |child| child[:id] })
  end

  filter :name
  filter :material_type, apply: ->(records, values, _options) {
    records.where(material_type: MaterialType.where(name: values))
  }

  def self.updatable_fields(context)
    super - [:created_at, :id]
  end

  def self.creatable_fields(context)
    super - [:created_at, :id]
  end
end
