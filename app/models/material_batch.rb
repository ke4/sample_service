class MaterialBatch < ApplicationRecord
  has_and_belongs_to_many :materials

  validates :materials, presence: true

  def self.build_from_params(params)
    material_batch = MaterialBatch.new(material_batch_create_params(params))

    ActiveRecord::Base.transaction do
      material_create_params(params).each { |param|
        material = Material.build_from_params(param)
        if material.errors.empty?
          material_batch.materials << material
        else
          material.errors.each { |key|
            material.errors[key].each { |error|
              material_batch.errors.add(key, error)
            }
          }
        end
      }

      unless material_batch.errors.empty?
        raise ActiveRecord::Rollback
      end
    end

    material_batch
  end

  def update_from_params(params)
    ActiveRecord::Base.transaction do
      if material_batch_update_params(params)[:attributes]
        self.update(material_batch_update_params(params)[:attributes])
      end

      if material_update_params(params)[:relationships] and material_update_params(params)[:relationships][:materials]
        material_update_params(params)[:relationships][:materials][:data].each { |param|
          if param[:id]
            material = Material.find(param[:id])
            material.update_from_params(param)

            unless self.materials.include? material
              self.materials << material
            end
          else
            material = Material.build_from_params(param)
            self.materials << material
          end
          material.errors.each { |key|
            material.errors[key].each { |error|
              self.errors.add(key, error)
            }
          }
        }
      end

      if self.errors.empty?
        return true
      else
        raise ActiveRecord::Rollback
      end
    end

    false
  end

  private

  # Only allow a trusted parameter "white list" through.
  def self.material_batch_create_params(params)
    params.require(:data).require(:attributes).permit(:name)
  end

  def self.material_create_params(params)
    params.require(:data).require(:relationships).require(:materials).require(:data)
  end

  def material_batch_update_params(params)
    params.require(:data).permit(attributes: [:name])
  end

  def material_update_params(params)
    params.require(:data).permit!
  end
end
