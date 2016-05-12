class Api::V1::ApplicationController < ActionController::API
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