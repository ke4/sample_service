class Api::V1::Helpers::MaterialParser
  def initialize(options)
    @params = options[:params]
    @material = options[:material]
  end

  def build
    material_type = MaterialType.find_by(material_type_create_params)
    metadata = metadata_create_params[:metadata].nil? ? [] : metadata_create_params[:metadata][:data].map { |metadatum| Metadatum.new(metadatum[:attributes]) }

    Material.new(material_create_params.merge(material_type: material_type, metadata: metadata))
  end

  def update
    material_type = @material.material_type
    unless material_type_update_params[:relationships].nil? or material_type_update_params[:relationships][:material_type].nil?
      material_type = MaterialType.find_by(material_type_update_params[:relationships][:material_type][:data][:attributes])
    end

    if metadata_update_params[:relationships] and metadata_update_params[:relationships][:metadata]
      metadata_update_params[:relationships][:metadata][:data].each do |new_metadatum|
        metadatum = @material.metadata.find { |metadatum| metadatum.key == new_metadatum[:attributes][:key] }
        if metadatum.nil?
          @material.metadata << Metadatum.new(new_metadatum[:attributes])
        else
          metadatum.value = new_metadatum[:attributes][:value]
        end
      end
    end

    @material.update((material_update_params[:attributes] or {}).merge(material_type: material_type))
    @material.metadata.each { |metadatum| metadatum.save }

    @material
  end

  private

  def material_create_params
    @params.require(:attributes).permit(:name, :uuid)
  end

  def material_type_create_params
    @params.require(:relationships).require(:material_type).require(:data).require(:attributes).permit(:name)
  end

  def metadata_create_params
    @params.require(:relationships).permit(metadata: {data: [attributes: [:key, :value]]})
  end

  def material_update_params
    @params.permit(attributes: [:name, :uuid])
  end

  def material_type_update_params
    @params.permit(relationships: {material_type: {data: {attributes: [:name]}}})
  end

  def metadata_update_params
    @params.permit(relationships: {metadata: {data: [attributes: [:key, :value]]}})
  end
end