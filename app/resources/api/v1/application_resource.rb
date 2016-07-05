class Api::V1::ApplicationResource < JSONAPI::Resource
  abstract

  attributes :created_at

  filter :created_before, apply: ->(records, values, _options) {
    min_date = values.map { |d| d.to_datetime }.min
    records.where('created_at <= ?', min_date)
  }
  filter :created_after, apply: ->(records, values, _options) {
    max_date = values.map { |d| d.to_datetime }.max
    records.where('created_at >= ?', max_date)
  }
end