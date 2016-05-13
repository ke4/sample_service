class Api::V1::ApplicationController < ActionController::API
# See README.md for copyright details

# GET /{plural_resource_name}
  def index
    plural_resource_name = "@#{resource_name.pluralize}"
    resources = filter(query_params)
        .page(page_params[:number])
        .per(page_params[:size])

    instance_variable_set(plural_resource_name, resources)
    resource = instance_variable_get(plural_resource_name)
    render json: resource, include: included_relations_to_render
  end

  # GET /{plural_resource_name}/{id|uuid}
  def show
    render json: get_resource, include: included_relations_to_render
  end

  private

  # Returns the resource from the created instance variable
  # @return [Object]
  def get_resource
    instance_variable_get("@#{resource_name}")
  end

  def included_relations_to_render
    []
  end

  # Returns the filtered array of resources
  # Override query_params to change what the
  # resource is filtered by
  # @return [Class]
  def filter(params)
    resources = resource_class

    params.each do |param_key, param_value|
      resources = resources.where("Api::V1::Filters::#{param_key.camelize}Filter".constantize.filter(params))
    end

    resources
  end

  # Returns the allowed parameters for searching
  # Override this method in each API controller
  # to permit additional parameters to search on
  # @return [Hash]
  def query_params
    {}
  end

  # Returns the allowed parameters for pagination
  # @return [Hash]
  def page_params
    params.permit(page: [:number, :size])[:page] or {}
  end

  # The resource class based on the controller
  # @return [Class]
  def resource_class
    @resource_class ||= resource_name.classify.constantize
  end

  # The singular name for the resource class based on the controller
  # @return [String]
  def resource_name
    @resource_name ||= self.controller_name.singularize
  end
end

class ActionController::Parameters
  def permit(params)
    filter(params, self)
  end

  private

  def filter(schema, object)
    if schema.is_a?(Array) and object.is_a?(Array)
      object.map { |obj| filter(schema, obj) }
    elsif schema.is_a?(Hash)
      output = {}
      schema.each { |k, v|
        if object.has_key?(k)
          output[k] = filter(v, object[k])
        end
      }
      output
    elsif schema.is_a?(Array)
      output = {}
      schema.each { |k|
        if k.is_a?(Symbol) and object.has_key?(k)
          output[k] = object[k]
        end
        if k.is_a?(Hash)
          k.each { |key, value|
            if object.has_key?(key)
              output[key] = filter(value, object[key])
            end
          }
        end
      }
      output
    end
  end
end