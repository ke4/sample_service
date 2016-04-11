# See README.md for copyright details

class UuidValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    unless /^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$/i.match(value)
      record.errors.add attribute, "(#{value}) #{I18n.t 'errors.invalid_uuid'}"
    end
  end
end