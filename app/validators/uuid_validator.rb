# See README.md for copyright details
require 'uuid'

class UuidValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless UUID.validate(value)
      record.errors.add attribute, I18n.t('errors.messages.invalid_uuid')
    end
  end
end