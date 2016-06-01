module MaterialParametersHelper
  extend ActiveSupport::Concern

  def material_json_schema
    {
        data: [
            :id,
            attributes: [
                :name
            ],
            relationships: {
                material_type: {
                    data: {
                        attributes: [
                            :name
                        ]
                    }
                },
                metadata: {
                    data: [
                        attributes: [
                            :key,
                            :value
                        ]
                    ]
                },
                parents: {
                    data: [
                        :id
                    ]
                }
            }
        ]
    }
  end
end