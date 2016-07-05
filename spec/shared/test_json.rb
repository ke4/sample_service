module TestJson
  def build_material_batch_with_metadata
    material_batch = build(:material_batch_with_metadata)

    {
        data: {
            relationships: {
                materials: {
                    data: material_batch.materials.map { |material| {
                        attributes: {
                            name: material.name
                        },
                        relationships: {
                            material_type: {
                                data: {
                                    attributes: {
                                        name: material.material_type.name
                                    }
                                }
                            },
                            metadata: {
                                data: material.metadata.map { |metadatum| {
                                    attributes: {
                                        key: metadatum.key,
                                        value: metadatum.value
                                    }
                                } }
                            }
                        }
                    } }
                }
            }
        }
    }
  end


end