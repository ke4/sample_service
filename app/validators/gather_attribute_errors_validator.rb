# See README.md for copyright details
class GatherAttributeErrorsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    value.each{ |child|
      child.errors.each { |key|
        child.errors[key].each { |error|
          record.errors.add "#{value.name.downcase}.#{key}", error
        }
      }
    }
  end
end